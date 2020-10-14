CREATE PROCEDURE [Manufactory].[TaskSample_Set]
	@sample_id INT,
	@task_sample_id INT,
	@qp_id TINYINT,
	@st_id TINYINT,
	@pattern_perimeter INT,
	@cut_perimeter INT,
	@ts_id INT = NULL,
	@ct_id INT,
	@pattern_employee_id INT,
	@cut_employee_id INT,
	@employee_id INT,
	@sample_is_deleted BIT,
	@task_is_deleted BIT
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @dt dbo.SECONDSTIME = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	DECLARE @st_stm TINYINT = 4
	DECLARE @is_stm BIT = 0
	DECLARE @sketch_id INT 
	
	IF @st_id = @st_stm
	BEGIN
	    SET @is_stm = 1
	END
	
	SELECT	@error_text = CASE 
	      	                   WHEN ts.task_sample_id IS NULL THEN 'Задания с кодом ' + CAST(v.task_sample_id AS VARCHAR(10)) + ' не существует.'
	      	                   WHEN ts.pattern_begin_work_dt IS NOT NULL AND @pattern_employee_id IS NULL THEN 
	      	                        'Задание в работе у помошника, удалять сотрудника лекал нельзя'
	      	                   WHEN ts.cut_begin_work_dt IS NOT NULL AND @cut_employee_id IS NULL THEN 
	      	                        'Задание в работе у помошника, удалять сотрудника кроя нельзя'
	      	                   WHEN oa.consumption IS NOT NULL AND @task_is_deleted = 1 THEN 'На это задание израсходован материал, удалять нельзя'
	      	                   WHEN oa.consumption IS NOT NULL AND oas.outer_sample IS NULL AND @sample_is_deleted = 1 THEN 
	      	                        'На это задание израсходован материал и в нем нет дургого макета/образца, удалять нельзя'
	      	                   WHEN oas.outer_sample IS NULL AND ((@task_is_deleted = 0 AND @sample_is_deleted = 1)) THEN 
	      	                        'В этом задании нет другого макета/образца, их удалять надо вмете'
	      	                   WHEN (oas.outer_sample IS NOT NULL AND @sample_is_deleted = 1) AND @task_is_deleted = 1 THEN 
	      	                        'Сначала в задании необходимо удалить все макеты/образцы, потом удалять само задание'
	      	                   ELSE NULL
	      	              END
	FROM	(VALUES(@task_sample_id))v(task_sample_id)   
			LEFT JOIN	Manufactory.TaskSample ts
				ON	ts.task_sample_id = v.task_sample_id   
			OUTER APPLY (
			      	SELECT	TOP(1) 1 consumption
			      	FROM	Warehouse.MaterialInSketch mis
			      	WHERE	mis.task_sample_id = ts.task_sample_id
			      			AND	mis.qty != ISNULL(mis.return_qty, 0)
			      ) oa
	OUTER APPLY (
	      	SELECT	TOP(1) 1                 outer_sample
	      	FROM	Manufactory.[Sample]     s
	      	WHERE	s.task_sample_id = ts.task_sample_id
	      			AND	s.sample_id != @sample_id
	      			AND	s.is_deleted = 0
	      ) oas
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	SELECT	@error_text = CASE 
	      	                   WHEN s.sample_id IS NULL THEN 'Макета/образца с кодом ' + CAST(v.sample_id AS VARCHAR(10)) + ' не существует'
	      	                   WHEN s.task_sample_id != @task_sample_id THEN 'Сэмпл не соответствует заданию'
	      	                   ELSE NULL
	      	              END,
			@sketch_id = s.sketch_id
	FROM	(VALUES(@sample_id))v(sample_id)   
			LEFT JOIN	Manufactory.[Sample] s
				ON	s.sample_id = v.sample_id
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	
	IF NOT EXISTS(
	   	SELECT	1
	   	FROM	Manufactory.SampleType st
	   	WHERE	st.st_id = @st_id
	   )
	BEGIN
	    RAISERROR('Некорректо указан тип макет/образец', 16, 1, @st_id)
	    RETURN
	END
	
	IF @ts_id IS NOT NULL
	   AND NOT EXISTS(
	       	SELECT	1
	       	FROM	Products.TechSize ts
	       	WHERE	ts.ts_id = @ts_id
	       )
	BEGIN
	    RAISERROR('Размера с кодом %d не существует', 16, 1, @ts_id)
	    RETURN
	END
	
	IF NOT EXISTS(
	   	SELECT	1
	   	FROM	Material.ClothType ct
	   	WHERE	ct.ct_id = @ct_id
	   )
	BEGIN
	    RAISERROR('Типа ткани с кодом %d не существует', 16, 1, @ct_id)
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
	
	IF @st_id = @st_stm
	   AND (@pattern_perimeter > 0 OR @cut_perimeter > 0)
	BEGIN
	    RAISERROR('Для стм периметры необходимо указывать равными 0.', 16, 1, @ct_id)
	    RETURN
	END
	
	BEGIN TRY
		BEGIN TRANSACTION
		
		UPDATE	Manufactory.TaskSample
		SET 	is_stm = @is_stm,
				ct_id = @ct_id,
				qp_id = @qp_id,
				pattern_employee_id = ISNULL(@pattern_employee_id, pattern_employee_id),
				cut_employee_id = ISNULL(@cut_employee_id, cut_employee_id),
				is_deleted = @task_is_deleted
		WHERE	task_sample_id = @task_sample_id
		
		UPDATE	Manufactory.[Sample]
		SET 	pattern_perimeter = @pattern_perimeter,
				cut_perimeter = @cut_perimeter,
				st_id = @st_id,
				ts_id = @ts_id,
				ct_id = @ct_id,
				is_deleted = @sample_is_deleted
		WHERE	sample_id = @sample_id
		
		UPDATE	s
		SET 	s.ct_id = @ct_id
		FROM	Products.Sketch s
		WHERE	s.sketch_id = @sketch_id
				AND	s.ct_id != @ct_id
		
		UPDATE	ts
		SET 	ts.ct_id = @ct_id
		FROM	Manufactory.TaskSew ts
				INNER JOIN	Manufactory.TaskSewSample tss
					ON	tss.ts_id = ts.ts_id
		WHERE	tss.sample_id = @sample_id
				AND	ts.ct_id != @ct_id
				AND ts.sew_begin_work_dt IS NULL
		
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