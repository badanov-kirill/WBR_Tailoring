CREATE PROCEDURE [Planing].[SketchPrePlan_CopyByXml]
	@data_xml XML,
	@model_year SMALLINT,
	@season_local_id INT,
	@employee_id INT
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @dt DATETIME2(0) = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	
	IF @model_year < (YEAR(@dt) - 1)
	   OR @model_year > (YEAR(@dt) + 2)
	BEGIN
	    RAISERROR('Некорректный год %d', 16, 1, @model_year)
	    RETURN
	END	
	
	IF NOT EXISTS(
	   	SELECT	1
	   	FROM	Products.SeasonLocal sl
	   	WHERE	sl.season_local_id = @season_local_id
	   )
	BEGIN
	    RAISERROR('Сезона коллекции с кодом (%d) не существует', 16, 1, @season_local_id)
	    RETURN
	END
	
	DECLARE @data_tab TABLE(spp_id INT PRIMARY KEY CLUSTERED)
	
	
	INSERT INTO @data_tab
		(
			spp_id
		)
	SELECT	ml.value('@spp[1]', 'int')
	FROM	@data_xml.nodes('root/det')x(ml)
	
	SELECT	@error_text = 'Не найдены следующие коды строчек предвартительного плана:' + CHAR(10)
	      	+ (
	      		SELECT	DISTINCT CAST(ISNULL(dt.spp_id, 0) AS VARCHAR(10)) + CHAR(10)
	      		FROM	@data_tab dt   
	      				LEFT JOIN	Planing.SketchPrePlan spp
	      					ON	spp.spp_id = dt.spp_id
	      		WHERE	spp.spp_id IS NULL
	      		FOR XML	PATH('')
	      	)	
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	
	SELECT	@error_text = 'Коллекцию ' + sl.season_local_name + ' ' + CAST(@model_year AS VARCHAR(10)) + ' бренда ' + b.brand_name 
	      	+ ' уже закрыл ' + ISNULL(es.employee_name, '') + ' , дата закрытия: ' + CONVERT(VARCHAR(20), cl.close_dt, 121) + ', копировать в неё нельзя.'
	FROM	Products.CollectionLocal cl   
			INNER JOIN	Products.SeasonLocal sl
				ON	sl.season_local_id = cl.season_local_id   
			INNER JOIN	Products.Brand b
				ON	b.brand_id = cl.brand_id   
			LEFT JOIN	Settings.EmployeeSetting es
				ON	es.employee_id = cl.close_employee_id
	WHERE	cl.season_model_year = @model_year
			AND	cl.season_local_id = @season_local_id
			AND	cl.close_dt IS NOT NULL
			AND	EXISTS (
			   		SELECT	1
			   		FROM	@data_tab dt   
			   				INNER JOIN	Planing.SketchPrePlan spp
			   					ON	spp.spp_id = dt.spp_id   
			   				INNER JOIN	Products.Sketch s
			   					ON	s.sketch_id = spp.sketch_id
			   		WHERE	s.brand_id = cl.brand_id
			   	)
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	BEGIN TRY
		BEGIN TRANSACTION 
		
		INSERT INTO Planing.SketchPrePlan
			(
				season_model_year,
				season_local_id,
				sketch_id,
				spps_id,
				create_employee_id,
				create_dt,
				employee_id,
				dt,
				sale_plan_dt,
				plan_dt,
				buy_material_plan_dt,
				sew_office_id,
				plan_qty,
				cv_qty
			)
		SELECT	@model_year               season_model_year,
				@season_local_id          season_local_id,
				s.sketch_id,
				1,
				@employee_id,
				@dt,
				@employee_id,
				@dt,
				NULL,
				NULL,
				NULL,
				NULL,
				s.plan_qty,
				s.cv_qty
		FROM	Planing.SketchPrePlan     s
		WHERE	EXISTS (
		     		SELECT	1
		     		FROM	@data_tab dt
		     		WHERE	dt.spp_id = s.spp_id
		     	)
		
		
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