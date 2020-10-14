CREATE PROCEDURE [Manufactory].[TaskChinaSample_Close]
	@tcs_id INT,
	@employee_id INT
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @dt dbo.SECONDSTIME = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	
	SELECT	@error_text = CASE 
	      	                   WHEN tcs.tcs_id IS NULL THEN 'Задания с номером ' + CAST(v.tcs_id AS VARCHAR(10)) + ' не существует'
	      	                   WHEN tcs.close_dt IS NOT NULL THEN 'Задания с номером ' + CAST(v.tcs_id AS VARCHAR(10)) + ' уже закрыто'
	      	                   WHEN s.is_china_sample = 0 THEN 'Это не Китайский образец.'
	      	                   ELSE NULL
	      	              END
	FROM	(VALUES(@tcs_id))v(tcs_id)   
			LEFT JOIN	Manufactory.TaskChinaSample tcs
				ON	tcs.tcs_id = v.tcs_id   
			LEFT JOIN	Products.Sketch s
				ON	s.sketch_id = tcs.sketch_id
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	
	BEGIN TRY
		BEGIN TRANSACTION
		
		UPDATE	tcs
		SET 	tcs.close_dt = @dt,
				tcs.close_employee_id = @employee_id
		FROM	Manufactory.TaskChinaSample tcs
		WHERE	tcs.tcs_id = @tcs_id
				AND	tcs.close_dt IS NULL
		
		IF @@ROWCOUNT = 0
		BEGIN
		    RAISERROR('Что-то пошло не так', 16, 1)
		    RETURN
		END
		
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