CREATE PROCEDURE [Manufactory].[TaskSample_Del]
	@task_sample_id INT,
	@employee_id INT
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	DECLARE @dt DATETIME2(0) = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	DECLARE @with_log BIT = 1
	
	SELECT	@error_text = CASE 
	      	                   WHEN ts.task_sample_id IS NULL THEN 'Задания с кодом ' + CAST(v.task_sample_id AS VARCHAR(10)) + ' не существует.'
	      	                   WHEN ts.is_deleted = 1 THEN 'Задание с кодом ' + CAST(v.task_sample_id AS VARCHAR(10)) + ' удалено.'
	      	                   WHEN ts.pattern_begin_work_dt IS NOT NULL OR ts.cut_begin_work_dt IS NOT NULL THEN 'Задание с кодом ' + CAST(v.task_sample_id AS VARCHAR(10)) + ' уже в работе. Удалять нельзя.'
	      	                   WHEN ts.slicing_dt IS NOT NULL THEN 'На задание с кодом ' + CAST(v.task_sample_id AS VARCHAR(10)) + ' уже подготовлена ткань. Удалять нельзя.'
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
		
		UPDATE	s
		SET 	s.is_deleted = 1,
				s.employee_id = @employee_id,
				s.dt = @dt,
				s.task_sample_id = NULL 
		FROM	Manufactory.[Sample] s
		WHERE	s.task_sample_id = @task_sample_id
		
		DELETE	ts
		FROM	Manufactory.TaskSample ts
		WHERE	ts.task_sample_id = @task_sample_id
				AND	ts.pattern_begin_work_dt IS NULL
				AND	ts.cut_begin_work_dt IS NULL
		
		IF @@ROWCOUNT = 0
		BEGIN
		    SET @with_log = 0
		    RAISERROR('Возможно задание успели взять в работу. Перечитайте данные и повторите попытку', 16, 1)
		    RETURN
		END
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