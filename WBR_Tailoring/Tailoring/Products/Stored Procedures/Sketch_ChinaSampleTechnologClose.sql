CREATE PROCEDURE [Products].[Sketch_ChinaSampleTechnologClose]
	@sketch_id INT,
	@employee_id INT
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @dt dbo.SECONDSTIME = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	DECLARE @state_complite_constructor TINYINT = 10 --Закончено конструирование
	DECLARE @state_complite_constructor_only_file TINYINT = 22 --Закончено конструирование только конструкция
	DECLARE @with_log BIT = 1
	DECLARE @status_sided_tailoring TINYINT = 9
	DECLARE @create_employee_id INT
	
	SELECT	@error_text = CASE 
	      	                   WHEN s.sketch_id IS NULL THEN 'Эскиза с номером ' + CAST(v.sketch_id AS VARCHAR(10)) + ' не существует'
	      	                   WHEN s.ss_id NOT IN (@state_complite_constructor, @state_complite_constructor_only_file) THEN 'Текущий статус ' + ss.ss_name 
	      	                        +
	      	                        ' установленый сотрудником с кодом' + CAST(s.employee_id AS VARCHAR(10)) 
	      	                        + ' ' + CONVERT(VARCHAR(20), s.dt, 121) +
	      	                        ' не допускает перехода в статус: "Закончена технология"'
	      	                   WHEN s.technology_dt IS NOT NULL THEN 'Уже закончен технологом'
	      	                   WHEN s.is_china_sample = 0 THEN 'Это не Китайский образец'
	      	                   ELSE NULL
	      	              END,
			@create_employee_id = s.create_employee_id
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
		SET 	s.technology_employee_id = @employee_id,
				s.technology_dt = @dt
		FROM	Products.Sketch s
		WHERE	s.sketch_id = @sketch_id
				AND	s.ss_id IN (@state_complite_constructor, @state_complite_constructor_only_file)
				AND	s.technology_dt IS NULL
		
		IF @@ROWCOUNT = 0
		BEGIN
		    SET @with_log = 0
		    RAISERROR('Кто то уже отредактировал статус, перечитайте и попробуйте снова', 16, 1)
		    RETURN
		END
		
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
		VALUES
			(
				@sketch_id,
				@status_sided_tailoring,
				@create_employee_id,
				@dt,
				@employee_id,
				@dt,
				2
			)
		
		
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