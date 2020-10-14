CREATE PROCEDURE [Products].[Sketch_ApproveTechDesignStatusSet]
	@sketch_id INT,
	@comment VARCHAR(250) = NULL,
	@employee_id INT
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @state_tech_desig_add TINYINT = 2 --Добавлен технический эскиз
	DECLARE @state_tech_design_amend TINYINT = 5 --Технический эскиз доработан
	DECLARE @state_tech_design_approve TINYINT = 3 --Технический эскиз утвержден дизайнером
	DECLARE @state_need_tect_desig_correction_from_constructor TINYINT = 11 --Тех. эскиз отправлен на доработку конструктором
	DECLARE @state_tech_desig_confirm_from_constructor TINYINT = 13 --Тех. эскиз доработан по требованию конструктора
	DECLARE @state_constructor_take_job_add TINYINT = 9 --Взят в работу конструктором
	DECLARE @with_log BIT = 1
	DECLARE @dt dbo.SECONDSTIME = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	DECLARE @sketch_output TABLE 
	        (
	        	sketch_id INT PRIMARY KEY CLUSTERED NOT NULL,
	        	ss_id TINYINT NOT NULL,
	        	employee_id INT NOT NULL,
	        	status_comment VARCHAR(250) NULL
	        )
	
	SELECT	@error_text = CASE 
	      	                   WHEN s.sketch_id IS NULL THEN 'Эскиза с номером ' + CAST(v.sketch_id AS VARCHAR(10)) + ' не существует'
	      	                   WHEN s.ss_id NOT IN (@state_tech_desig_add, @state_tech_design_amend, @state_tech_desig_confirm_from_constructor, @state_need_tect_desig_correction_from_constructor) THEN 
	      	                        'Текущий статус ' + ss.ss_name +
	      	                        ' установленый сотрудником с кодом ' + CAST(s.employee_id AS VARCHAR(10))
	      	                        + ' ' + CONVERT(VARCHAR(20), s.dt, 121) +
	      	                        ' не допускает перехода в статус: "Технический эскиз утвержден дизайнером"'
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
		    	             WHEN s.ss_id = @state_tech_desig_confirm_from_constructor THEN @state_constructor_take_job_add
		    	             WHEN s.ss_id = @state_need_tect_desig_correction_from_constructor THEN @state_constructor_take_job_add
		    	             ELSE @state_tech_design_approve
		    	        END,
				status_comment = CASE 
				                      WHEN @comment IS NULL THEN status_comment
				                      WHEN @comment = '' THEN NULL
				                      ELSE @comment
				                 END,
				employee_id = @employee_id,
				dt = @dt
				OUTPUT	INSERTED.sketch_id,
						INSERTED.ss_id,						
						INSERTED.employee_id,
						INSERTED.status_comment
				INTO	@sketch_output (
						sketch_id,
						ss_id,
						employee_id,
						status_comment
					)
		FROM	Products.Sketch s
		WHERE	s.sketch_id = @sketch_id
				AND	s.ss_id IN (@state_tech_desig_add, @state_tech_design_amend, @state_tech_desig_confirm_from_constructor, @state_need_tect_desig_correction_from_constructor)
		
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
				status_comment				
			)
		SELECT	so.sketch_id,			
				so.ss_id,
				so.employee_id,
				@dt dt,
				so.status_comment
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