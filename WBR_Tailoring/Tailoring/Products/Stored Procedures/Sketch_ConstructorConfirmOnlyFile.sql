CREATE PROCEDURE [Products].[Sketch_ConstructorConfirmOnlyFile]
	@sketch_id INT,
	@comment VARCHAR(250) = NULL,
	@employee_id INT
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @state_constructor_take_job_add TINYINT = 9 --Взят в работу конструктором	
	DECLARE @state_complite_constructor_only_file TINYINT = 22 --Закончено конструирование только конструкция
	DECLARE @state_constructor_take_job_add_rework TINYINT = 15 --Взят на доработку конструктором
	DECLARE @state_complite_constructor_rework_only_file TINYINT = 23 --Доработан конструктором только конструкция
	DECLARE @with_log BIT = 1
	DECLARE @dt DATETIME2(0) = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	DECLARE @status_sided_tailoring TINYINT = 9
	DECLARE @create_employee_id INT
	DECLARE @qp_id TINYINT = 2
	DECLARE @is_china_sample BIT
	
	SELECT	@error_text = CASE 
	      	                   WHEN s.sketch_id IS NULL THEN 'Эскиза с номером ' + CAST(v.sketch_id AS VARCHAR(10)) + ' не существует'
	      	                   WHEN s.ss_id NOT IN (@state_constructor_take_job_add, @state_constructor_take_job_add_rework) THEN 'Текущий статус ' + ss.ss_name 
	      	                        +
	      	                        ' установленый сотрудником с кодом' + CAST(s.employee_id AS VARCHAR(10)) 
	      	                        + ' ' + CONVERT(VARCHAR(20), s.dt, 121) +
	      	                        ' не допускает перехода в статус: "Закончено конструирование" или "Доработан конструктором"'

	      	                   ELSE NULL
	      	              END,
	      	              @create_employee_id = s.create_employee_id,
	      	              @is_china_sample = s.is_china_sample
	FROM	(VALUES(@sketch_id))v(sketch_id)   
			LEFT JOIN	Products.Sketch s
				ON	s.sketch_id = v.sketch_id   
			LEFT JOIN	Products.SketchStatus ss
				ON	ss.ss_id = s.ss_id   
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	BEGIN TRY
		BEGIN TRANSACTION
		
		UPDATE	s
		SET 	ss_id = CASE 
		    	             WHEN s.ss_id = @state_constructor_take_job_add THEN @state_complite_constructor_only_file
		    	             ELSE @state_complite_constructor_rework_only_file
		    	        END
		    	             ,
				status_comment = CASE 
				                      WHEN @comment IS NULL THEN status_comment
				                      WHEN @comment = '' THEN NULL
				                      ELSE @comment
				                 END,
				employee_id = @employee_id,
				dt = @dt,
				pattern_print_dt =  pattern_print_dt,
				construction_close_dt = ISNULL(s.construction_close_dt, @dt)
				OUTPUT	INSERTED.sketch_id,
						INSERTED.ss_id,
						INSERTED.employee_id,
						INSERTED.dt,
						INSERTED.status_comment,
						INSERTED.plan_site_dt
				INTO	History.SketchStatus (
						sketch_id,
						ss_id,
						employee_id,
						dt,
						status_comment,
						plan_site_dt
					)
		FROM	Products.Sketch s
		WHERE	s.sketch_id = @sketch_id
				AND	s.ss_id IN (@state_constructor_take_job_add, @state_constructor_take_job_add_rework)
		
		IF @@ROWCOUNT = 0
		BEGIN
		    SET @with_log = 0
		    RAISERROR('Кто то уже отредактировал статус, перечитайте и попробуйте снова', 16, 1)
		    RETURN
		END
		
		IF @is_china_sample = 1
		BEGIN	
			INSERT INTO Planing.SketchPlan
				(
					sketch_id,
					ps_id,
					create_employee_id,
					create_dt,
					employee_id,
					dt,
					qp_id
				)OUTPUT	INSERTED.sp_id,
			 			INSERTED.sketch_id,
			 			INSERTED.ps_id,
			 			INSERTED.employee_id,
			 			INSERTED.dt,
			 			INSERTED.comment
				 INTO	History.SketchPlan (
			 			sp_id,
			 			sketch_id,
			 			ps_id,
			 			employee_id,
			 			dt,
			 			comment
			 		)
			SELECT 	@sketch_id,
					@status_sided_tailoring,
					@create_employee_id,
					@dt,
					@employee_id,
					@dt,
					@qp_id
			WHERE NOT EXISTS (
			                 	SELECT	1
			                 	FROM	Planing.SketchPlan sp
			                 	WHERE	sp.sketch_id = @sketch_id
			                 )
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