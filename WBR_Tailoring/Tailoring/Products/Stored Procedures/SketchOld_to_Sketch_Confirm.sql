CREATE PROCEDURE [Products].[SketchOld_to_Sketch_Confirm_v2]
	@so_id INT,
	@sketch_id INT,
	@employee_id INT
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	DECLARE @dt dbo.SECONDSTIME = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	
	SELECT	@error_text = CASE 
	      	                   WHEN so.so_id IS NULL THEN 'Архивного эскиза с кодом ' + CAST(v.so_id AS VARCHAR(10)) + ' не существует'
	      	                   WHEN s.sketch_id IS NULL THEN 'Артикула с кодом ' + CAST(v.sketch_id AS VARCHAR(10)) + ' не существует'
	      	                   --WHEN so.brand_id IS NULL OR so.st_id IS NULL OR so.subject_id IS NULL OR so.season_id IS NULL OR so.model_year IS NULL OR so.sa_local 
	      	                   --     IS NULL OR so.model_number IS NULL OR so.art_name IS NULL OR so.brand_id != s.brand_id OR so.model_year != s.art_year OR 
	      	                   --     so.st_id != s.st_id OR so.subject_id != s.subject_id OR so.season_id != s.season_id OR so.sa_local != s.sa_local OR so.model_number 
	      	                   --     != s.model_number
	      	                   --     OR s.art_name_id != an.art_name_id THEN 'Не совпадают данные у старого и нового артикула, невозможно завершить перенос'
	      	                   ELSE NULL
	      	              END
	FROM	(VALUES(@sketch_id,
			@so_id))v(sketch_id,
			so_id)   
			LEFT JOIN	Products.SketchOld so   
			LEFT JOIN	Products.ArtName an
				ON	an.art_name = so.art_name
				ON	so.so_id = v.so_id    
			LEFT JOIN	Products.Sketch s
				ON	s.sketch_id = v.sketch_id
	
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	BEGIN TRY
		BEGIN TRANSACTION
		
		UPDATE	Products.SketchOld
		SET 	is_deleted = 1,
				employee_id = @employee_id,
				dt = @dt
		WHERE	so_id = @so_id
		
		
		UPDATE	Products.Sketch
		SET 	is_deleted = 0,
				employee_id = @employee_id,
				dt = @dt
		WHERE	sketch_id = @sketch_id
		
		
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