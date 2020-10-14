CREATE PROCEDURE [Manufactory].[ProblemTaskSampleReWork]
	@task_sample_id INT,
	@employee_id INT
AS
	SET NOCOUNT ON
	DECLARE @dt dbo.SECONDSTIME = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	
	SELECT	@error_text = CASE 
	      	                   WHEN ts.task_sample_id IS NULL THEN 'Задания с номером ' + CAST(v.task_sample_id AS VARCHAR(10)) + ' не существует'
	      	                   WHEN ts.problem_dt IS NULL THEN 'Задания с номером ' + CAST(v.task_sample_id AS VARCHAR(10)) 
	      	                        + ' уже не отложено'
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
		UPDATE	Manufactory.TaskSample
		SET 	problem_dt          = NULL,
				problem_comment     = NULL,
				employee_id         = @employee_id,
				dt                  = @dt
		WHERE	task_sample_id      = @task_sample_id
				AND	problem_dt IS NOT NULL
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