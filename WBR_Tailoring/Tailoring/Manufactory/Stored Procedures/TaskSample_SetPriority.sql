CREATE PROCEDURE [Manufactory].[TaskSample_SetPriority]
	@task_sample_id INT,
	@qp_id TINYINT
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @error_text VARCHAR(MAX)
	DECLARE @tss_id INT
	
	SELECT	@error_text = CASE 
	      	                   WHEN ts.task_sample_id IS NULL THEN 'Задания с кодом ' + CAST(v.task_sample_id AS VARCHAR(10)) + ' не существует.'
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
	
	IF NOT EXISTS (
	   	SELECT	1
	   	FROM	Products.QueuePriority qp
	   	WHERE	qp.qp_id = @qp_id
	   )
	BEGIN
	    RAISERROR('Приоритета очередности с кодом %d не существует', 16, 1, @qp_id)
	    RETURN
	END
	
	
	
	
	BEGIN TRY
		BEGIN TRANSACTION
		
		UPDATE	Manufactory.TaskSample
		SET 	qp_id = @qp_id
		WHERE	task_sample_id = @task_sample_id
		
		UPDATE	ts
		SET 	qp_id = @qp_id
		FROM	Manufactory.TaskSew ts
				INNER JOIN	Manufactory.TaskSewSample tss
					ON	tss.ts_id = ts.ts_id
				INNER JOIN	Manufactory.[Sample] s
					ON	s.sample_id = tss.sample_id
		WHERE	s.task_sample_id = @task_sample_id
				AND	ts.sew_begin_work_dt IS NULL
		
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