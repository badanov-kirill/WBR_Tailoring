CREATE PROCEDURE [Manufactory].[TaskSew_Rework]
	@ts_id INT,
	@employee_id INT,
	@comment VARCHAR(500) = NULL
AS
	
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @dt dbo.SECONDSTIME = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	DECLARE @sew_employee_id INT

		SELECT	@error_text = CASE 
	      	                   WHEN ts.ts_id IS NULL THEN 'Задания с номером ' + CAST(v.ts_id AS VARCHAR(10)) + ' не существует'
	      	                   WHEN ts.sew_end_work_dt IS NULL THEN 'Задания с номером ' + CAST(v.ts_id AS VARCHAR(10)) 
	      	                        + ' ещё не закрыто'
	      	                   WHEN tsr.ts_id IS NOT NULL THEN 'На это задание уже создана заявка на переделку.'
	      	                   WHEN tsr2.ts_id IS NOT NULL THEN 'Это задание само является переделкой, веберете базовое задание.'
	      	                   ELSE NULL
	      	              END,
	      	@sew_employee_id = ts.sew_employee_id
	FROM	(VALUES(@ts_id))v(ts_id)   
			LEFT JOIN	Manufactory.TaskSew ts
				ON	ts.ts_id = v.ts_id
			LEFT JOIN Manufactory.TaskSewRework tsr
				ON tsr.ts_id = ts.ts_id AND tsr.close_dt IS NOT NULL
			LEFT JOIN Manufactory.TaskSewRework tsr2
				ON tsr2.new_ts_id = ts.ts_id
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	BEGIN TRY
		
		INSERT INTO Manufactory.TaskSewRework
		(
			ts_id,
			create_dt,
			create_employee_id,
			sew_employee_id,
			close_dt,
			close_employee_id,
			new_ts_id,
			comment
		)
		VALUES
		(
			@ts_id,
			@dt,
			@employee_id,
			@sew_employee_id,
			NULL,
			NULL,
			NULL,
			@comment
		)		
		
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
