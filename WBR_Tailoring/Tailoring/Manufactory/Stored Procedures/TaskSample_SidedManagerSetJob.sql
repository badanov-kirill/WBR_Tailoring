CREATE PROCEDURE [Manufactory].[TaskSample_SidedManagerSetJob]
	@sketch_id INT,
	@task_sample_id INT,
	@employee_id INT
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @dt dbo.SECONDSTIME = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	DECLARE @with_log BIT = 1
	
	
	SELECT	@error_text = CASE 
	      	                   WHEN ts.task_sample_id IS NULL THEN 'Задания с номером ' + CAST(v.task_sample_id AS VARCHAR(10)) + ' не существует'
	      	                   WHEN ts.is_deleted = 1 THEN 'Задание с кодом ' + CAST(v.task_sample_id AS VARCHAR(10)) + ' удалено.'
	      	                   WHEN ts.cut_end_of_work_dt IS NOT NULL THEN 'Задание уже закрыто'
	      	                   WHEN oa.sketch_id IS NULL THEN 'В задании с номером ' + CAST(v.task_sample_id AS VARCHAR(10)) + ' нет эскиза № ' + CAST(@sketch_id AS VARCHAR(10))
	      	                   WHEN ts.is_stm = 0 THEN 'Задания с номером ' + CAST(v.task_sample_id AS VARCHAR(10)) + ' не СТМ'
	      	                   ELSE NULL
	      	              END
	FROM	(VALUES(@task_sample_id))v(task_sample_id)   
			LEFT JOIN	Manufactory.TaskSample ts  
				ON ts.task_sample_id = v.task_sample_id 
			OUTER APPLY (
			      	SELECT TOP(1)	s.sketch_id
			      	FROM	Manufactory.[Sample] s
			      	WHERE	s.task_sample_id = ts.task_sample_id
			      			AND	s.sketch_id = @sketch_id
			      ) oa			
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	BEGIN TRY
		BEGIN TRANSACTION		
		
		UPDATE	Manufactory.TaskSample
		SET 	pattern_employee_id        = @employee_id,
				pattern_begin_work_dt      = @dt,
				pattern_end_of_work_dt     = @dt,
				cut_employee_id            = @employee_id,
				cut_begin_work_dt          = @dt
		WHERE	task_sample_id             = @task_sample_id
				AND	pattern_employee_id IS NULL
		
		IF @@ROWCOUNT = 0
		BEGIN
		    SET @with_log = 0
		    RAISERROR('Перечитайте данные и повторите попытку, возможно это задание уже взяли в работу', 16, 1)
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
		
		IF @with_log = 1
		BEGIN
		    RAISERROR('Ошибка %d в строке %d  %s', @esev, @estate, @ErrNum, @Line, @Mess) WITH LOG;
		END
		ELSE
		BEGIN
		    RAISERROR('Ошибка %d в строке %d  %s', @esev, @estate, @ErrNum, @Line, @Mess)
		END
	END CATCH 