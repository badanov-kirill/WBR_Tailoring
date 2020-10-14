CREATE PROCEDURE [Manufactory].[CuttingPlan_Set]
	@office_id INT,
	@plan_year SMALLINT,
	@plan_month TINYINT,
	@employee_id INT,
	@data_xml XML
AS
	SET NOCOUNT ON;
	DECLARE @dt dbo.SECONDSTIME = GETDATE()
	DECLARE @data TABLE (pants_id INT, plan_count SMALLINT, perimeter INT, pt_id TINYINT, plan_start_dt DATE)
	DECLARE @error_text VARCHAR(MAX)
	DECLARE @cutting_tariff DECIMAL(9,6)
	
	IF @plan_month < 1
	   OR @plan_month > 12
	BEGIN
	    RAISERROR('Некорректный месяц %d', 16, 1, @plan_month)
	    RETURN
	END
	
	IF @plan_year < 2015
	BEGIN
	    RAISERROR('Некорректный год %d', 16, 1, @plan_year)
	    RETURN
	END
	
	INSERT INTO @data
	  (
	    pants_id,
	    plan_count,
	    perimeter,
	    pt_id,
	    plan_start_dt
	  )
	SELECT	ml.value('@id', 'int')           pants_id,
			ml.value('@pln', 'smallint')     plan_count,
			ml.value('@per', 'int')          perimeter,
			ml.value('@pt', 'tinyint')       pt_id,
			ml.value('@sdt','date') plan_start_dt
	FROM	@data_xml.nodes('root/detail')x(ml)
	
	SELECT	@error_text = CASE 
	      	                   WHEN os.office_id IS NULL THEN 'Офиса с кодом ' + CAST(v.office_id AS VARCHAR(10)) + ' не существует'
	      	                   ELSE NULL
	      	              END,
			@cutting_tariff = os.cutting_tariff
	FROM	(VALUES(@office_id))v(office_id)   
			LEFT JOIN	Settings.OfficeSetting os
				ON	os.office_id = v.office_id
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	SELECT	@error_text = CASE 
	      	                   WHEN pants.pants_id IS NULL THEN 'Цветоразмера с кодом ' + CAST(d.pants_id AS VARCHAR(10)) + ' не существует'
	      	                   WHEN pt.pt_id IS NULL THEN 'Типа продукта с кодом ' + CAST(d.pt_id AS VARCHAR(3)) + ' не существует'
	      	                   WHEN s.pt_id IS NULL THEN 'У эскиза ' + s.sa_local + ' не заполнен тип продукта.'
	      	                   WHEN s.pt_id != d.pt_id THEN 'У эскиза ' + s.sa_local + ' не совпадает тип продукта.'
	      	                   WHEN pan.nm_id IS NULL THEN 'Артикул ' + pa.sa + ' не записан на сайт'
	      	                   ELSE NULL
	      	              END
	FROM	@data d   
			LEFT JOIN	Products.ProdArticleNomenclatureTechSize pants   
			INNER JOIN	Products.ProdArticleNomenclature pan
				ON	pan.pan_id = pants.pan_id   
			INNER JOIN	Products.ProdArticle pa
				ON	pa.pa_id = pan.pa_id   
			INNER JOIN	Products.Sketch s
				ON	s.sketch_id = pa.sketch_id
				ON	pants.pants_id = d.pants_id   
			LEFT JOIN	Products.ProductType pt
				ON	pt.pt_id = d.pt_id
	WHERE	pants.pants_id IS NULL
			OR	pt.pt_id IS NULL
			OR	s.pt_id IS NULL
			OR	s.pt_id != d.pt_id
			OR pan.nm_id IS NULL
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	BEGIN TRY
		;
		MERGE Manufactory.Cutting t
		USING (
		      	SELECT	@office_id       office_id,
		      			@plan_year       plan_year,
		      			@plan_month      plan_month,
		      			d.pants_id,
		      			@employee_id     employee_id,
		      			@dt              dt,
		      			d.plan_count     plan_count,
		      			d.perimeter      perimeter,
		      			d.pt_id,
		      			d.plan_start_dt,
		      			@cutting_tariff cutting_tariff
		      	FROM	@data            d
		      ) s
				ON t.office_id = s.office_id
				AND t.plan_year = s.plan_year
				AND t.plan_month = s.plan_month
				AND t.pants_id = s.pants_id
		WHEN MATCHED THEN 
		     UPDATE	
		     SET 	employee_id     = s.employee_id,
		     		dt              = s.dt,
		     		plan_count      = s.plan_count,
		     		perimeter       = s.perimeter,
		     		pt_id           = s.pt_id,
		     		plan_start_dt	= s.plan_start_dt,
		     		cutting_tariff  = s.cutting_tariff
		WHEN NOT MATCHED BY TARGET THEN 
		     INSERT
		     	(
		     		office_id,
		     		plan_year,
		     		plan_month,
		     		pants_id,
		     		plan_count,
		     		create_employee_id,
		     		create_dt,
		     		employee_id,
		     		dt,
		     		perimeter,
		     		pt_id,
		     		plan_start_dt,
		     		cutting_tariff
		     	)
		     VALUES
		     	(
		     		s.office_id,
		     		s.plan_year,
		     		s.plan_month,
		     		s.pants_id,
		     		s.plan_count,
		     		s.employee_id,
		     		s.dt,
		     		s.employee_id,
		     		s.dt,
		     		s.perimeter,
		     		s.pt_id,
		     		s.plan_start_dt,
		     		s.cutting_tariff
		     	)
		WHEN NOT MATCHED BY SOURCE AND t.office_id = @office_id AND t.plan_year = @plan_year
		     AND t.plan_month = @plan_month THEN 
		     UPDATE	
		     SET 	t.employee_id = @employee_id,
		     		t.dt = @dt,
		     		t.plan_count = 0;
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
		    ROLLBACK TRANSACTION
		
		DECLARE @ErrNum INT = ERROR_NUMBER();
		DECLARE @estate INT = ERROR_STATE();
		DECLARE @esev INT = ERROR_SEVERITY();
		DECLARE @Line INT = ERROR_LINE();
		DECLARE @Mess VARCHAR(MAX) = CHAR(10) + ISNULL('Процедура: ' + ERROR_PROCEDURE(), '') 
		        + CHAR(10) + ERROR_MESSAGE();
		
		RAISERROR('Ошибка %d в строке %d  %s', @esev, @estate, @ErrNum, @Line, @Mess) 
		WITH LOG;
	END CATCH