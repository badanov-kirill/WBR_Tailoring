CREATE PROCEDURE [Manufactory].[RepairPlan_Add]
	@office_id INT,
	@plan_year SMALLINT,
	@plan_month TINYINT,
	@data_xml XML,
	@employee_id INT,
	@pt_id TINYINT = NULL
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @dt dbo.SECONDSTIME = GETDATE()
	DECLARE @data_tab TABLE (pants_id INT, plan_count SMALLINT, pt_id INT)
	DECLARE @error_text VARCHAR(MAX)
	DECLARE @cutting_output TABLE(cutting_id INT, plan_count SMALLINT)
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
	
	INSERT INTO @data_tab
	  (
	    pants_id,
	    plan_count,
	    pt_id
	  )
	SELECT	ml.value('@id[1]', 'int') pants_id,
			ml.value('@cnt[1]', 'smallint') cnt,
			s.pt_id
	FROM	@data_xml.nodes('root/det')x(ml)   
			LEFT JOIN	Products.ProdArticleNomenclatureTechSize pants   
			INNER JOIN	Products.ProdArticleNomenclature pan
				ON	pan.pan_id = pants.pan_id   
			INNER JOIN	Products.ProdArticle pa
				ON	pa.pa_id = pan.pa_id   
			INNER JOIN	Products.Sketch s
				ON	s.sketch_id = pa.sketch_id
				ON	pants.pants_id = ml.value('@id[1]',
			'int') 
	
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
	      	                   WHEN pan.nm_id IS NULL THEN 'Артикул ' + pa.sa + ' не записан на сайт'
	      	                   WHEN @pt_id IS NULL AND d.pt_id IS NULL THEN 'У эскиза ' + s.sa_local + ' не заполнен тип продукта.'
	      	                   ELSE NULL
	      	              END
	FROM	@data_tab d   
			LEFT JOIN	Products.ProdArticleNomenclatureTechSize pants   
			INNER JOIN	Products.ProdArticleNomenclature pan
				ON	pan.pan_id = pants.pan_id   
			INNER JOIN	Products.ProdArticle pa
				ON	pa.pa_id = pan.pa_id   
			INNER JOIN	Products.Sketch s
				ON	s.sketch_id = pa.sketch_id
				ON	pants.pants_id = d.pants_id
	WHERE	pants.pants_id IS NULL
			OR	pan.nm_id IS NULL
			OR	d.pt_id IS NULL
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	BEGIN TRY
		BEGIN TRANSACTION
		
		IF @pt_id IS NOT NULL
		BEGIN
		    UPDATE	s
		    SET 	pt_id = @pt_id
		    FROM	Products.Sketch s
		    WHERE	EXISTS (
		         		SELECT	1
		         		FROM	@data_tab dt   
		         				INNER JOIN	Products.ProdArticleNomenclatureTechSize pants
		         					ON	pants.pants_id = dt.pants_id   
		         				INNER JOIN	Products.ProdArticleNomenclature pan
		         					ON	pan.pan_id = pants.pan_id   
		         				INNER JOIN	Products.ProdArticle pa
		         					ON	pa.pa_id = pan.pa_id
		         		WHERE	pa.sketch_id = s.sketch_id
		         	)
		END
		
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
		      			0                perimeter,
		      			ISNULL(@pt_id, d.pt_id) pt_id,
		      			@cutting_tariff  cutting_tariff
		      	FROM	@data_tab        d
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
		     		pt_id           = s.pt_id,
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
		     		planing_employee_id,
		     		planing_dt,
		     		closing_employee_id,
		     		closing_dt,
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
		     		s.employee_id,
		     		s.dt,
		     		s.employee_id,
		     		s.dt,
		     		s.dt,
		     		s.cutting_tariff
		     	) 
		     OUTPUT	INSERTED.cutting_id,
		     		INSERTED.plan_count
		     INTO	@cutting_output (
		     		cutting_id,
		     		plan_count
		     	);		
		
		INSERT INTO Manufactory.CuttingActual
		  (
		    cutting_id,
		    actual_count,
		    dt,
		    employee_id
		  )
		SELECT	co.cutting_id,
				co.plan_count,
				@dt,
				@employee_id
		FROM	@cutting_output co
		WHERE	co.plan_count > 0
		
		COMMIT TRANSACTION
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