CREATE PROCEDURE [Products].[Sketch_ConstructorGiveToWork]
	@sketch_id INT,
	@comment VARCHAR(250) = NULL,
	@employee_id INT
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @state_tech_design_approve TINYINT = 3 --Технический эскиз утвержден дизайнером
	DECLARE @state_appointed_constructor TINYINT = 8 --Назначен конструктору
	DECLARE @state_complite_constructor TINYINT = 10 --Закончено конструирование
	DECLARE @state_appointed_constructor_rework TINYINT = 14 --Назначен на доработку конструктору
	DECLARE @state_complite_constructor_rework TINYINT = 16 --Доработан конструктором
	DECLARE @state_tech_desig_confirm_from_desig TINYINT = 19 -- Тех. эскиз с готовой конструкцией доработан
	DECLARE @state_complite_constructor_only_file TINYINT = 22 --Закончено конструирование только конструкция  
	DECLARE @state_complite_constructor_rework_only_file TINYINT = 23 --Доработан конструктором только конструкция 
	
	DECLARE @with_log BIT = 1
	DECLARE @dt dbo.SECONDSTIME = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	
	SELECT	@error_text = CASE 
	      	                   WHEN s.sketch_id IS NULL THEN 'Эскиза с номером ' + CAST(v.sketch_id AS VARCHAR(10)) + ' не существует'
	      	                   WHEN s.constructor_employee_id IS NULL THEN 'У данного эскиза не указан конструктор'
	      	                   WHEN s.is_deleted = 1 THEN 'Нельзя назначать на контруктора помеченные на удаление эскизы'
	      	                   WHEN s.tech_design = 0 THEN 'У данного эскиза не выполнен техдизайн'
	      	                   WHEN s.ss_id NOT IN (@state_tech_design_approve, @state_complite_constructor, @state_complite_constructor_rework,
	      							@state_tech_desig_confirm_from_desig, @state_complite_constructor_only_file, @state_complite_constructor_rework_only_file) 
	      							THEN 'Текущий статус ' + ss.ss_name +
	      	                        ' установленый сотрудником с кодом ' + CAST(s.employee_id AS VARCHAR(10))
	      	                        + ' ' + CONVERT(VARCHAR(20), s.dt, 121) +
	      	                        ' не допускает перехода в статус: "Назначен конструктору"'
	      	                   WHEN s.ss_id = @state_tech_design_approve AND oa_com.sketch_id IS NULL THEN 'Необходимо сначала указать комплектацию'
	      	                   ELSE NULL
	      	              END
	FROM	(VALUES(@sketch_id))v(sketch_id)   
			LEFT JOIN	Products.Sketch s
				ON	s.sketch_id = v.sketch_id   
			LEFT JOIN	Products.SketchStatus ss
				ON	ss.ss_id = s.ss_id   
			OUTER APPLY (
			      	SELECT	TOP(1) sc.sketch_id
			      	FROM	Products.SketchCompleting sc
			      	WHERE	sc.sketch_id = s.sketch_id
			      	ORDER BY
			      		sc.sc_id
			      ) oa_com
		
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	BEGIN TRY
		BEGIN TRANSACTION
		
		
		UPDATE	s
		SET 	ss_id              = CASE 
		    	             WHEN s.ss_id = @state_tech_design_approve THEN @state_appointed_constructor
		    	             ELSE @state_appointed_constructor_rework
		    	        END,
				status_comment     = CASE 
				                      WHEN @comment IS NULL THEN status_comment
				                      WHEN @comment = '' THEN NULL
				                      ELSE @comment
				                 END,
				employee_id        = @employee_id,
				dt                 = @dt,
				in_constructor_dt  = ISNULL(in_constructor_dt, @dt)		
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
				AND	s.ss_id IN (@state_tech_design_approve, @state_complite_constructor, @state_complite_constructor_rework, 
				@state_tech_desig_confirm_from_desig, @state_complite_constructor_only_file, @state_complite_constructor_rework_only_file)
		
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