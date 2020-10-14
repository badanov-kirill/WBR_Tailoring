CREATE PROCEDURE [Manufactory].[TaskSew_Add]
	@employee_id INT,
	@xml_data XML,
	@qp_id TINYINT,
	@office_id INT,
	@priority_employee_id INT = NULL,
	@comment VARCHAR(500) = NULL,
	@estimated_time SMALLINT = NULL
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @data_tab TABLE (sample_id INT)
	DECLARE @error_text VARCHAR(MAX)
	DECLARE @ct_id INT
	DECLARE @dt dbo.SECONDSTIME = GETDATE()
	DECLARE @ts_id INT
	DECLARE @with_log BIT = 1
	DECLARE @tsr_id INT
	
	IF NOT EXISTS (
	   	SELECT	1
	   	FROM	Products.QueuePriority qp
	   	WHERE	qp.qp_id = @qp_id
	   )
	BEGIN
	    RAISERROR('Приоритета очередности с кодом %d не существует', 16, 1, @qp_id)
	    RETURN
	END
	
	IF @office_id IS NULL
	BEGIN
	    RAISERROR('Не указан офис', 16, 1)
	    RETURN
	END
	
	INSERT INTO @data_tab
	  (
	    sample_id
	  )
	SELECT	ml.value('@id', 'int')
	FROM	@xml_data.nodes('samples/sample')x(ml)
	
	
	SELECT	@error_text = CASE 
	      	                   WHEN s.sample_id IS NULL THEN 'Макета/образца с кодом ' + CAST(dt.sample_id AS VARCHAR(10)) + ' не существует'
	      	                   WHEN s.is_deleted = 1 THEN 'Нельзя добавлять помеченные на удаление макеты/образцы'
	      	                   WHEN ts.ts_id IS NOT NULL AND ts.sew_end_work_dt IS NULL THEN 'Макет/образец с кодом ' + CAST(s.sample_id AS VARCHAR(10)) +
	      	                        ' уже в задании № ' + CAST(ts.ts_id AS VARCHAR(10))
	      	                   ELSE NULL
	      	              END
	FROM	@data_tab dt   
			LEFT JOIN	Manufactory.[Sample] s
				ON	s.sample_id = dt.sample_id   
			LEFT JOIN	Manufactory.TaskSewSample tss   
			INNER JOIN	Manufactory.TaskSew ts
				ON	ts.ts_id = tss.ts_id
				ON	tss.sample_id = s.sample_id
	WHERE	s.sample_id IS NULL
			OR	s.is_deleted = 1
			OR	s.task_sample_id IS NOT NULL
			OR  (ts.ts_id IS NOT NULL AND ts.sew_end_work_dt IS NULL )
	
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	SELECT	@error_text = CASE 
	      	                   WHEN v.cnt = 0 THEN 'Не переданы макеты/образцы для задания'
	      	                   WHEN v.cnt != v.cnt_dst THEN 'Переданы макеты/образцы с дублями'
	      	                   WHEN v.cnt_sketch > 1 THEN 'В одно задание нельзя добавлять макеты/образцы от разных эскизов'
	      	                   WHEN v.cnt_ct > 1 THEN 'В одно задание нельзя добавлять макеты/образцы из разных типов ткани'
	      	                   ELSE NULL
	      	              END,
			@ct_id = v.ct_id
	FROM	(SELECT	COUNT(s.sample_id)     cnt,
	    	 		COUNT(DISTINCT s.sample_id) cnt_dst,
	    	 		COUNT(DISTINCT s.sketch_id) cnt_sketch,
	    	 		COUNT(DISTINCT s.ct_id) cnt_ct,
	    	 		MAX(s.ct_id)           ct_id
	    	 FROM	@data_tab dt   
	    	 		INNER JOIN	Manufactory.[Sample] s
	    	 			ON	s.sample_id = dt.sample_id)v	
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	SELECT	@tsr_id = tsr.tsr_id
	FROM	@data_tab dt   
			INNER JOIN	Manufactory.[Sample] s
				ON	s.sample_id = dt.sample_id   
			INNER JOIN	Manufactory.TaskSewSample tss
				ON	tss.sample_id = s.sample_id   
			INNER JOIN	Manufactory.TaskSewRework tsr
				ON	tsr.ts_id = tss.ts_id
				AND	tsr.close_dt IS NULL
	
	IF @tsr_id IS NOT NULL AND @priority_employee_id IS NULL
	BEGIN
		RAISERROR('Для переделки приоритетный сотрудник обязателен',16,1)
		RETURN
	END
	
	BEGIN TRY
		BEGIN TRANSACTION
		
		INSERT INTO Manufactory.TaskSew
		  (
		    ct_id,
		    qp_id,
		    employee_id,
		    dt,
		    create_dt,
		    is_deleted,
		    office_id,
		    priority_employee_id,
		    comment,
		    estimated_time
		  )
		VALUES
		  (
		    @ct_id,
		    @qp_id,
		    @employee_id,
		    @dt,
		    @dt,
		    0,
		    @office_id,
		    @priority_employee_id,
		    @comment,
		    @estimated_time
		  )
		
		SET @ts_id = SCOPE_IDENTITY()
		
		INSERT INTO Manufactory.TaskSewSample
		  (
		    ts_id,
		    sample_id,
		    dt,
		    employee_id
		  )
		SELECT	@ts_id,
				t.sample_id,
				@dt,
				@employee_id
		FROM	@data_tab t
		
		
		UPDATE	s
		SET 	sew_launch_dt = @dt,
				sew_launch_employee_id = @employee_id
		FROM	Manufactory.[Sample] s
				INNER JOIN	@data_tab dt
					ON	dt.sample_id = s.sample_id
		WHERE	s.sew_launch_dt IS NULL
		
		UPDATE	tss
		SET 	tss.close_problem_employee_id = @employee_id,
				tss.close_problem_dt = @dt
		FROM	Manufactory.TaskSewSample tss
				INNER JOIN	Manufactory.[Sample] s
					ON	s.sample_id = tss.sample_id
				INNER JOIN	@data_tab dt
					ON	dt.sample_id = s.sample_id
		WHERE	tss.has_problem_dt IS NOT NULL
				AND	tss.close_problem_dt IS NULL
				
		UPDATE	tsr
		SET 	tsr.new_ts_id = @ts_id,
				tsr.close_dt = @dt,
				tsr.close_employee_id = @employee_id
		FROM	Manufactory.TaskSewRework tsr
		WHERE	tsr.tsr_id = @tsr_id			
		
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