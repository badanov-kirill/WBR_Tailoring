CREATE PROCEDURE [Products].[CollectionLocal_Close]
	@model_year SMALLINT,
	@season_local_id INT,
	@brand_id INT,
	@employee_id INT
AS
	SET NOCOUNT ON
	DECLARE @dt DATETIME2(0)	
	DECLARE @error_text VARCHAR(MAX)
	DECLARE @spps_state_del TINYINT = 3 --удален
	
	IF @model_year < (YEAR(@dt) - 3)
	   OR @model_year > (YEAR(@dt) + 3)
	   OR @model_year IS NULL
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
	
	IF NOT EXISTS (
	   	SELECT	1
	   	FROM	Products.Brand b
	   	WHERE	b.brand_id = @brand_id
	   )
	BEGIN
	    RAISERROR('Бренда с кодом (%d) не существует', 16, 1, @brand_id)
	    RETURN
	END
	
	SELECT	@error_text = CASE 
	      	                   WHEN cl.season_model_year IS NULL THEN 'Коллекции ' + sl.season_local_name + ' ' + CAST(@model_year AS VARCHAR(10)) + ' бренда ' 
	      	                        + b.brand_name + '  не существует'
	      	                   WHEN cl.close_dt IS NOT NULL THEN 'Коллекции ' + sl.season_local_name + ' ' + CAST(@model_year AS VARCHAR(10)) + ' бренда ' + b.brand_name 
	      	                        + ' уже закрыл ' + ISNULL(es.employee_name, '') + ' , дата закрытия: ' + CONVERT(VARCHAR(20), cl.close_dt, 121)
	      	                   ELSE NULL
	      	              END
	FROM	(VALUES(@model_year,
			@season_local_id,
			@brand_id))v(season_model_year,
			season_local_id,
			brand_id)   
			LEFT JOIN	Products.SeasonLocal sl
				ON	sl.season_local_id = v.season_local_id   
			LEFT JOIN	Products.Brand b
				ON	b.brand_id = v.brand_id   
			LEFT JOIN	Products.CollectionLocal cl
				ON	cl.season_model_year = v.season_model_year
				AND	cl.season_local_id = v.season_local_id
				AND	cl.brand_id = v.brand_id   
			LEFT JOIN	Settings.EmployeeSetting es
				ON	es.employee_id = cl.close_employee_id
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	SELECT	@error_text = 'Ошибки:' + CHAR(10)
	      	+ (
	      		SELECT	CASE 
	      		      	     WHEN ISNULL(spp.plan_qty, 0) = 0 THEN 'У ' + sj.subject_name + ' ' + an.art_name + '(' + s.sa + ') код эскиза: ' + CAST(s.sketch_id AS VARCHAR(10)) 
	      		      	          + ' не указано плановое количество ' + CHAR(10)
	      		      	     WHEN ISNULL(spp.cv_qty, 0) = 0 THEN 'У ' + sj.subject_name + ' ' + an.art_name + '(' + s.sa + ') код эскиза: ' + CAST(s.sketch_id AS VARCHAR(10)) 
	      		      	          + ' не указано плановое количество цветовариантов ' + CHAR(10)
	      		      	     WHEN spp.plan_dt IS NULL THEN 'У ' + sj.subject_name + ' ' + an.art_name + '(' + s.sa + ') код эскиза: ' + CAST(s.sketch_id AS VARCHAR(10)) 
	      		      	          + ' не указана плановая дата сдачи ' + CHAR(10)
	      		      	END
	      		FROM	Planing.SketchPrePlan spp   
	      				INNER JOIN	Products.Sketch s
	      					ON	s.sketch_id = spp.sketch_id   
	      				INNER JOIN	Products.[Subject] sj
	      					ON	sj.subject_id = s.subject_id   
	      				INNER JOIN	Products.ArtName an
	      					ON	an.art_name_id = s.art_name_id
	      		WHERE	spp.season_model_year = @model_year
	      				AND	spp.season_local_id = @season_local_id
	      				AND	s.brand_id = @brand_id
	      				AND	spp.spps_id != @spps_state_del
	      				AND	(ISNULL(spp.plan_qty, 0) = 0 OR ISNULL(spp.cv_qty, 0) = 0 OR spp.plan_dt IS NULL)
	      		FOR XML	PATH('')
	      	)	
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	BEGIN TRY
		BEGIN TRANSACTION 
		
		UPDATE	Products.CollectionLocal
		SET 	close_dt = @dt,
				close_employee_id = @employee_id
		WHERE	season_model_year = @model_year
				AND	season_local_id = @season_local_id
				AND	brand_id = @brand_id
				AND	close_dt IS NULL
		
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