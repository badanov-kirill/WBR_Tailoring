CREATE PROCEDURE [Manufactory].[TaskSample_SetSided]
	@task_sample_id INT,
	@employee_id INT,
	@comment VARCHAR(250) = NULL
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	DECLARE @dt DATETIME2(0) = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	DECLARE @with_log BIT = 1
	DECLARE @st_stm TINYINT = 4
	
	SELECT	@error_text = CASE 
	      	                   WHEN ts.task_sample_id IS NULL THEN 'Задания с кодом ' + CAST(v.task_sample_id AS VARCHAR(10)) + ' не существует.'
	      	                   WHEN ts.is_deleted = 1 THEN 'Задание с кодом ' + CAST(v.task_sample_id AS VARCHAR(10)) + ' удалено.'
	      	                   WHEN ts.pattern_employee_id IS NOT NULL OR ts.cut_employee_id IS NOT NULL THEN 'Задание уже в работе у помошника конструктора.'
	      	                   WHEN ts.is_stm = 1 THEN 'Задание уже отправлено на СТМ'
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
		SET 	is_stm = 1,
				problem_comment = @comment,
				dt = @dt
		WHERE	task_sample_id = @task_sample_id
				AND	pattern_employee_id IS NULL
		
		IF @@ROWCOUNT = 0
		BEGIN
		    SET @with_log = 0
		    RAISERROR('Перечитайте данные и повторите попытку, возможно это задание уже взяли в работу', 16, 1)
		    RETURN
		END
		
		UPDATE	Manufactory.[Sample]
		SET 	pattern_perimeter = 0,
				cut_perimeter = 0,
				st_id = @st_stm
		WHERE	task_sample_id = @task_sample_id
		
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
		
		IF @with_log = 1
		BEGIN
		    RAISERROR('Ошибка %d в строке %d  %s', @esev, @estate, @ErrNum, @Line, @Mess) WITH LOG;
		END
		ELSE
		BEGIN
		    RAISERROR('Ошибка %d в строке %d  %s', @esev, @estate, @ErrNum, @Line, @Mess)
		END
	END CATCH 