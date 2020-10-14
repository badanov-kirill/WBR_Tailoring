CREATE PROCEDURE [Products].[Sketch_ConstructorConfirm]
	@sketch_id INT,
	@comment VARCHAR(250) = NULL,
	@employee_id INT,
	@pattern_print BIT = NULL
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @state_constructor_take_job_add TINYINT = 9 --Взят в работу конструктором	
	DECLARE @state_complite_constructor TINYINT = 10 --Закончено конструирование
	DECLARE @state_constructor_take_job_add_rework TINYINT = 15 --Взят на доработку конструктором
	DECLARE @state_complite_constructor_rework TINYINT = 16 --Доработан конструктором
	DECLARE @state_appointed_constructor_rework TINYINT = 14 --Назначен на доработку конструктору
	DECLARE @with_log BIT = 1
	DECLARE @dt dbo.SECONDSTIME = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	
	SELECT	@error_text = CASE 
	      	                   WHEN s.sketch_id IS NULL THEN 'Эскиза с номером ' + CAST(v.sketch_id AS VARCHAR(10)) + ' не существует'
	      	                   WHEN s.ss_id NOT IN (@state_constructor_take_job_add, @state_constructor_take_job_add_rework) THEN 'Текущий статус ' + ss.ss_name 
	      	                        +
	      	                        ' установленый сотрудником с кодом' + CAST(s.employee_id AS VARCHAR(10)) 
	      	                        + ' ' + CONVERT(VARCHAR(20), s.dt, 121) +
	      	                        ' не допускает перехода в статус: "Закончено конструирование" или "Доработан конструктором"'
	      	                   WHEN oa_perim.sketch_id IS NOT NULL THEN 'Не на все размеры есть периметры'
	      	                   WHEN oa_com.sketch_id IS NULL THEN 'Необходимо сначала указать комплектацию'
	      	                   WHEN s.specification_dt IS NULL THEN 'Необходимо сначала загрузить спецификацию'
	      	                   WHEN ISNULL(oa_com.consumption, 0) = 0 THEN 'Необходимо указать расход во всех строчках комплектации'
	      	                   WHEN s.ss_id = @state_constructor_take_job_add AND s.layout_dt IS NULL THEN 'Без раскладки закрывать нельзя'
	      	                   WHEN oa_fw.sc_id IS NOT NULL THEN 'У элемента комплектации ' + oa_fw.completing_name + ' ' + CAST(oa_fw.completing_number AS VARCHAR(10)) + ' необходимо заполнить параметр - шир./дл./диам.'
	      	                   ELSE NULL
	      	              END
	FROM	(VALUES(@sketch_id))v(sketch_id)   
			LEFT JOIN	Products.Sketch s
				ON	s.sketch_id = v.sketch_id   
			LEFT JOIN	Products.SketchStatus ss
				ON	ss.ss_id = s.ss_id   
			OUTER APPLY (
			      	SELECT	TOP(1) sts.sketch_id
			      	FROM	Products.SketchTechSize sts   
			      			LEFT JOIN	Products.SketchPatternPerimetr spp
			      				ON	spp.sketch_id = s.sketch_id
			      				AND	spp.ts_id = sts.ts_id
			      	WHERE	sts.sketch_id = s.sketch_id
			      			AND	spp.spp_id IS NULL
			      ) oa_perim
			OUTER APPLY (
	      			SELECT	TOP(1) sc.sketch_id, sc.consumption
	      			FROM	Products.SketchCompleting sc
	      			WHERE	sc.sketch_id = s.sketch_id AND sc.is_deleted = 0
	      			ORDER BY
	      				CASE 
	      					 WHEN ISNULL(sc.consumption, 0) = 0 THEN 0
	      					 ELSE 1
	      				END,
	      				sc.sc_id
				  ) oa_com
			OUTER APPLY (
	      			SELECT	TOP(1) sc.sc_id,
	      					c.completing_name,
	      					sc.completing_number
	      			FROM	Products.SketchCompleting sc   
	      					INNER JOIN	Material.Completing c
	      						ON	c.completing_id = sc.completing_id
	      			WHERE	sc.sketch_id = s.sketch_id
	      					AND	sc.is_deleted = 0
	      					AND	c.required_frame_width = 1
	      					AND	ISNULL(sc.frame_width, 0) = 0
	      			ORDER BY sc.sc_id
				  ) oa_fw
			
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	BEGIN TRY
		BEGIN TRANSACTION
		
		UPDATE	s
		SET 	ss_id = CASE 
		    	             WHEN s.ss_id = @state_constructor_take_job_add THEN @state_complite_constructor
		    	             ELSE @state_complite_constructor_rework
		    	        END,
				status_comment = CASE 
				                      WHEN @comment IS NULL THEN status_comment
				                      WHEN @comment = '' THEN NULL
				                      ELSE @comment
				                 END,
				employee_id = @employee_id,
				dt = @dt,
				pattern_print_dt = CASE 
				                        WHEN pattern_print_dt IS NOT NULL THEN pattern_print_dt
				                        WHEN @pattern_print = 1 THEN @dt
				                        ELSE pattern_print_dt
				                   END,
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
		
		IF ISNULL(@pattern_print, 0) = 0
		BEGIN
			UPDATE	s
			SET 	ss_id = @state_appointed_constructor_rework,					
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
		END
		
		UPDATE	s
		SET 	s.technology_dt = @dt
		FROM	Products.Sketch s
		WHERE	s.sketch_id = @sketch_id
				AND s.is_china_sample = 0
				AND	s.technology_dt IS NULL
				AND	NOT EXISTS (
				   		SELECT	1
				   		FROM	Products.SketchTechnologyJob stj
				   		WHERE	stj.sketch_id = s.sketch_id
				   	)
		
		IF @@ROWCOUNT != 0
		BEGIN
		    INSERT INTO Products.SketchTechnologyJob
		      (
		        sketch_id,
		        create_dt,
		        create_employee_id,
		        qp_id
		      )
		    VALUES
		      (
		        @sketch_id,
		        @dt,
		        @employee_id,
		        3
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