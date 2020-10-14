CREATE PROCEDURE [Products].[Sketch_RejectTechDesignStatusSet]
	@sketch_id INT,
	@comment VARCHAR(250) = NULL,
	@employee_id INT
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @state_tech_desig_add TINYINT = 2 --Добавлен технический эскиз
	DECLARE @state_tech_design_approve TINYINT = 3 --Технический эскиз утвержден дизайнером
	DECLARE @state_tech_design_amend TINYINT = 5 --Технический эскиз доработан
	DECLARE @state_tech_design_reject TINYINT = 4 --Технический эскиз отклонен дизайнером
	DECLARE @state_complite_constructor TINYINT = 10 --Закончено конструирование
	DECLARE @state_complite_constructor_rework TINYINT = 16 ----Доработан конструктором
	DECLARE @state_need_tect_desig_correction_from_desig TINYINT = 17 --	Тех. эскиз c гот. констр. отпр. на доработку диз-м
	DECLARE @with_log BIT = 1
	DECLARE @dt dbo.SECONDSTIME = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	
	SELECT	@error_text = CASE 
	      	                   WHEN s.sketch_id IS NULL THEN 'Эскиза с номером ' + CAST(v.sketch_id AS VARCHAR(10)) + ' не существует'
	      	                   WHEN s.ss_id NOT IN (@state_tech_desig_add, @state_tech_design_amend, @state_tech_design_approve, @state_complite_constructor,
	      	                   @state_complite_constructor_rework) THEN 
	      	                        'Текущий статус ' + ss.ss_name 
	      	                        +
	      	                        ' установленый сотрудником с кодом ' + CAST(s.employee_id AS VARCHAR(10)) 
	      	                        + ' ' + CONVERT(VARCHAR(20), s.dt, 121) +
	      	                        ' не допускает перехода в статус: "Технический эскиз отклонен дизайнером"'
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
		    	             WHEN s.ss_id IN (@state_complite_constructor, @state_complite_constructor_rework) THEN @state_need_tect_desig_correction_from_desig
		    	             ELSE @state_tech_design_reject
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
				AND	s.ss_id IN (@state_tech_desig_add, @state_tech_design_amend, @state_tech_design_approve, @state_complite_constructor, @state_complite_constructor_rework)
		
		IF @@ROWCOUNT = 0
		BEGIN
		    SET @with_log = 0
		    RAISERROR('Кто то уже отредактировал статус, перечитайте и попробуйте снова', 16, 1)
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