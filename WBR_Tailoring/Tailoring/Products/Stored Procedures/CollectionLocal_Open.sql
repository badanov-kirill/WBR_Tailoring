CREATE PROCEDURE [Products].[CollectionLocal_Open]
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
	      	                   WHEN cl.close_dt IS NULL THEN 'Коллекция ' + sl.season_local_name + ' ' + CAST(@model_year AS VARCHAR(10)) + ' бренда ' + b.brand_name 
	      	                        + ' не закрыта'
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
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	BEGIN TRY
		BEGIN TRANSACTION 
		
		UPDATE	Products.CollectionLocal
		SET 	close_dt = NULL,
				close_employee_id = NULL
		WHERE	season_model_year = @model_year
				AND	season_local_id = @season_local_id
				AND	brand_id = @brand_id
				AND	close_dt IS NOT NULL
		
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