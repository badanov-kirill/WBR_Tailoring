CREATE PROCEDURE [Manufactory].[TaskSample_Add]
	@employee_id INT,
	@xml_data XML,
	@qp_id TINYINT,
	@office_id INT
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @data_tab TABLE (sample_id INT)
	DECLARE @error_text VARCHAR(MAX)
	DECLARE @ct_id INT
	DECLARE @dt dbo.SECONDSTIME = GETDATE()
	DECLARE @task_sample_id INT
	DECLARE @with_log BIT = 1
	DECLARE @rc INT
	DECLARE @pattern_perimeter INT
	DECLARE @cut_perimeter INT
	DECLARE @st_stm TINYINT = 4
	DECLARE @is_stm BIT = 0
	
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
	      	                   WHEN s.task_sample_id IS NOT NULL THEN 'Макет/образец с кодом ' + CAST(s.sample_id AS VARCHAR(10)) + ' уже в задании № ' + CAST(s.task_sample_id AS VARCHAR(10))
	      	                   ELSE NULL
	      	              END
	FROM	@data_tab dt   
			LEFT JOIN	Manufactory.[Sample] s
				ON	s.sample_id = dt.sample_id
	WHERE	s.sample_id IS NULL
			OR	s.is_deleted = 1
			OR	s.task_sample_id IS NOT NULL
	
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
	      	                   WHEN v.cnt_stm > 0 AND v.cnt != v.cnt_stm THEN 'В задании с стм, должен быть только стм.'
	      	                   ELSE NULL
	      	              END,
			@ct_id = v.ct_id,
			@rc = v.cnt,
			@pattern_perimeter = v.spp,
			@cut_perimeter = v.scp,
			@is_stm = CASE 
			               WHEN v.cnt_stm > 0 THEN 1
			               ELSE 0
			          END
	FROM	(SELECT	COUNT(s.sample_id)       cnt,
	    	 		COUNT(DISTINCT s.sample_id) cnt_dst,
	    	 		COUNT(DISTINCT s.sketch_id) cnt_sketch,
	    	 		COUNT(DISTINCT s.ct_id) cnt_ct,
	    	 		SUM(s.pattern_perimeter) spp,
	    	 		SUM(s.cut_perimeter)     scp,
	    	 		MAX(s.ct_id)             ct_id,
	    	 		SUM(CASE WHEN s.st_id = @st_stm THEN 1 ELSE 0 END) cnt_stm
	    	 FROM	@data_tab dt   
	    	 		INNER JOIN	Manufactory.[Sample] s
	    	 			ON	s.sample_id = dt.sample_id)v	
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	
	BEGIN TRY
		BEGIN TRANSACTION
		
		INSERT INTO Manufactory.TaskSample
		  (
		    ct_id,
		    qp_id,
		    employee_id,
		    dt,
		    is_deleted,
		    office_id,
		    pattern_employee_id,
		    pattern_begin_work_dt,
		    pattern_end_of_work_dt,
		    cut_employee_id,
		    cut_begin_work_dt,
		    cut_end_of_work_dt,
		    create_dt,
		    is_stm,
		    slicing_dt, 
		    slicing_employee_id
		    		  )
		SELECT	@ct_id           ct_id,
				@qp_id           qp_id,
				@employee_id     employee_id,
				@dt              dt,
				0                is_deleted,
				@office_id       office_id,
				CASE 
				     WHEN ISNULL(@pattern_perimeter, 0) = 0 AND @is_stm = 0 THEN @employee_id
				     ELSE NULL
				END              pattern_employee_id,
				CASE 
				     WHEN ISNULL(@pattern_perimeter, 0) = 0 AND @is_stm = 0 THEN @dt
				     ELSE NULL
				END              pattern_begin_work_dt,
				CASE 
				     WHEN ISNULL(@pattern_perimeter, 0) = 0 AND @is_stm = 0 THEN @dt
				     ELSE NULL
				END              pattern_end_of_work_dt,
				CASE 
				     WHEN ISNULL(@cut_perimeter, 0) = 0 AND @is_stm = 0 THEN @employee_id
				     ELSE NULL
				END              cut_employee_id,
				CASE 
				     WHEN ISNULL(@cut_perimeter, 0) = 0 AND @is_stm = 0 THEN @dt
				     ELSE NULL
				END              cut_begin_work_dt,
				CASE 
				     WHEN ISNULL(@cut_perimeter, 0) = 0 AND @is_stm = 0 THEN @dt
				     ELSE NULL
				END              cut_end_of_work_dt,
				@dt create_dt,
				@is_stm,
				CASE 
				     WHEN ISNULL(@cut_perimeter, 0) = 0 OR @is_stm = 1  THEN @dt
				     ELSE NULL
				END              slicing_dt,
				CASE 
				     WHEN ISNULL(@cut_perimeter, 0) = 0 OR @is_stm = 1 THEN @employee_id
				     ELSE NULL
				END slicing_employee_id    
		
		SET @task_sample_id = SCOPE_IDENTITY()
		
		UPDATE	s
		SET 	task_sample_id = @task_sample_id
		FROM	Manufactory.[Sample] s
				INNER JOIN	@data_tab dt
					ON	dt.sample_id = s.sample_id
		WHERE	s.task_sample_id IS NULL
		
		IF @rc != @@ROWCOUNT
		BEGIN
		    SET @with_log = 0
		    RAISERROR('Перечитайте данные и повторите попытку', 16, 1)
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