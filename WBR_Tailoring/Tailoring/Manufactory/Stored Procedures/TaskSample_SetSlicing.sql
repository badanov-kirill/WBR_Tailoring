CREATE PROCEDURE [Manufactory].[TaskSample_SetSlicing]
	@task_sample_id INT,
	@employee_id INT
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	DECLARE @dt DATETIME2(0) = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	
	
	SELECT	@error_text = CASE 
	      	                   WHEN ts.task_sample_id IS NULL THEN 'Задания с кодом ' + CAST(v.task_sample_id AS VARCHAR(10)) + ' не существует.'
	      	                   WHEN ts.is_deleted = 1 THEN 'Задание с кодом ' + CAST(v.task_sample_id AS VARCHAR(10)) + ' удалено.'
	      	                   WHEN ts.slicing_dt IS NOT NULL THEN 'Задание уже в помечено как прошедшее подготовку ткани.'
	      	                   ELSE NULL
	      	              END
	FROM	(VALUES(@task_sample_id))v(task_sample_id)   
			LEFT JOIN	Manufactory.TaskSample ts
				ON	ts.task_sample_id = v.task_sample_id
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	BEGIN TRY
		BEGIN TRANSACTION
		
		UPDATE	Manufactory.TaskSample
		SET 	slicing_dt = @dt,
				slicing_employee_id = @employee_id
		WHERE	task_sample_id = @task_sample_id
				AND	slicing_dt IS NULL
		
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