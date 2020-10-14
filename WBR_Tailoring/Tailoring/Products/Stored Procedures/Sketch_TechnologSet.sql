﻿CREATE PROCEDURE [Products].[Sketch_TechnologSet]
	@sketch_id INT,
	@technology_employee_id INT,
	@employee_id INT
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @dt dbo.SECONDSTIME = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	
	SELECT	@error_text = CASE 
	      	                   WHEN s.sketch_id IS NULL THEN 'Эскиза с номером ' + CAST(v.sketch_id AS VARCHAR(10)) + ' не существует'
	      	                   ELSE NULL
	      	              END
	FROM	(VALUES(@sketch_id))v(sketch_id)   
			LEFT JOIN	Products.Sketch s
				ON	s.sketch_id = v.sketch_id   	
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	BEGIN TRY
		BEGIN TRANSACTION
		
		UPDATE	s
		SET 	s.technology_employee_id = @technology_employee_id,
				employee_id = @employee_id,
				dt = @dt
				--OUTPUT	INSERTED.sketch_id,
				--		INSERTED.ss_id,
				--		INSERTED.employee_id,
				--		INSERTED.dt,
				--		INSERTED.status_comment
				--INTO	History.SketchStatus (
				--		sketch_id,
				--		ss_id,
				--		employee_id,
				--		dt,
				--		status_comment
				--	)
		FROM	Products.Sketch s
		WHERE	s.sketch_id = @sketch_id
		
		
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
		
		RAISERROR('Ошибка %d в строке %d  %s', @esev, @estate, @ErrNum, @Line, @Mess) WITH LOG;
	END CATCH 