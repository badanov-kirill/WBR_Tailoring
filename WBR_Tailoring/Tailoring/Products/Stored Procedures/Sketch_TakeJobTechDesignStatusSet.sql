﻿CREATE PROCEDURE [Products].[Sketch_TakeJobTechDesignStatusSet]
	@sketch_id INT,
	@employee_id INT
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @state_create TINYINT = 1 --Создан
	DECLARE @state_tech_design_reject TINYINT = 4 --Технический эскиз отклонен дизайнером
	DECLARE @state_tech_desig_take_job_add TINYINT = 6 --Взято в работу техническис дизайнером
	DECLARE @state_tech_design_take_job_amend TINYINT = 7 --Взято на исправление техническим дизайнером
	DECLARE @state_need_tect_desig_correction_from_constructor TINYINT = 11 --Тех. эскиз отправлен на доработку конструктором
	DECLARE @state_tech_design_take_job_amend_from_constructor TINYINT = 12 --Тех. эскиз взят на исправление от конструктора
	DECLARE @state_need_tect_desig_correction_from_desig TINYINT = 17 --	Тех. эскиз c гот. констр. отпр. на доработку диз-м
	DECLARE @state_tech_design_take_job_amend_from_desig TINYINT = 18 --	Тех. эскиз c гот. констр. взят на дораб-у от диз-а
	DECLARE @with_log BIT = 1
	DECLARE @dt dbo.SECONDSTIME = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	DECLARE @sketch_output TABLE 
	        (
	        	sketch_id INT PRIMARY KEY CLUSTERED NOT NULL,
	        	ss_id TINYINT NOT NULL,
	        	employee_id INT NOT NULL,
	        	status_comment VARCHAR(250) NULL,
	        	plan_site_dt	DATE NULL
	        )
	
	SELECT	@error_text = CASE 
	      	                   WHEN s.sketch_id IS NULL THEN 'Эскиза с номером ' + CAST(v.sketch_id AS VARCHAR(10)) + ' не существует'
	      	                   WHEN s.ss_id NOT IN (@state_create, @state_tech_design_reject, @state_need_tect_desig_correction_from_constructor, @state_need_tect_desig_correction_from_desig) THEN 'Текущий статус ' + ss.ss_name + 
	      	                        ' установленый сотрудником с кодом' + CAST(s.employee_id AS VARCHAR(10)) 
	      	                        + ' ' + CONVERT(VARCHAR(20), s.dt, 121) +
	      	                        ' не допускает перехода в статус: "Добавлен технический эскиз" или "Технический эскиз доработан"'
	      	                   ELSE NULL
	      	              END
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
		    	             WHEN s.ss_id = @state_create THEN @state_tech_desig_take_job_add
		    	             WHEN s.ss_id = @state_tech_design_reject THEN @state_tech_design_take_job_amend
		    	             WHEN s.ss_id = @state_need_tect_desig_correction_from_constructor THEN @state_tech_design_take_job_amend_from_constructor
		    	             WHEN s.ss_id = @state_need_tect_desig_correction_from_desig THEN @state_tech_design_take_job_amend_from_desig
		    	        END,
				employee_id = @employee_id,
				dt = @dt
				OUTPUT	INSERTED.sketch_id,
						INSERTED.ss_id,						
						INSERTED.employee_id,
						INSERTED.status_comment,
						INSERTED.plan_site_dt
				INTO	@sketch_output (
						sketch_id,
						ss_id,
						employee_id,
						status_comment,
						plan_site_dt
					)
		FROM	Products.Sketch s
		WHERE	s.sketch_id = @sketch_id
				AND	s.ss_id IN (@state_create, @state_tech_design_reject, @state_need_tect_desig_correction_from_constructor, @state_need_tect_desig_correction_from_desig)
		
		IF NOT EXISTS (
		   	SELECT	1
		   	FROM	@sketch_output
		   )
		BEGIN
		    SET @with_log = 0
		    RAISERROR('Кто то уже отредактировал статус, перечитайте и попробуйте снова', 16, 1)
		    RETURN
		END
		
		INSERT INTO History.SketchStatus
			(
				sketch_id,			
				ss_id,				
				employee_id,
				dt,			
				status_comment,
				plan_site_dt				
			)
		SELECT	so.sketch_id,			
				so.ss_id,
				so.employee_id,
				@dt dt,
				so.status_comment,
				so.plan_site_dt
		FROM	@sketch_output so
				
		COMMIT TRANSACTION
		
		SELECT	so.sketch_id,
				so.ss_id,
				ss.ss_name
		FROM	@sketch_output so   
				INNER JOIN	Products.SketchStatus ss
					ON	ss.ss_id = so.ss_id
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