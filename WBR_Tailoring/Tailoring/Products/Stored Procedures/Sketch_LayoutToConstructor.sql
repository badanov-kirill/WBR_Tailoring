CREATE PROCEDURE [Products].[Sketch_LayoutToConstructor]
	@sketch_id INT,
	@employee_id INT
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	

	DECLARE @state_appointed_layout TINYINT = 20 --Назначен раскладсику 
	DECLARE @state_appointed_layout_end TINYINT = 21 --Закончено прикрепление раскладок    
	DECLARE @complitying_cons TABLE (completing_id INT, completing_number TINYINT, consumption DECIMAL(9, 3), frame_width SMALLINT)                                                                                                 
	
	DECLARE @dt dbo.SECONDSTIME = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	DECLARE @with_log BIT = 1
	DECLARE @sketch_output TABLE 
	        (sketch_id INT PRIMARY KEY CLUSTERED NOT NULL, ss_id TINYINT NOT NULL, employee_id INT NOT NULL, status_comment VARCHAR(250) NULL, plan_site_dt DATE)
	
	SELECT	@error_text = CASE 
	      	                   WHEN s.sketch_id IS NULL THEN 'Эскиза с номером ' + CAST(v.sketch_id AS VARCHAR(10)) + ' не существует'
	      	                   WHEN s.ss_id NOT IN (@state_appointed_layout) THEN 'Текущий статус ' + ss.ss_name 
	      	                        +
	      	                        ' установленый сотрудником с кодом ' + CAST(s.employee_id AS VARCHAR(10)) 
	      	                        + ' ' + CONVERT(VARCHAR(20), s.dt, 121) +
	      	                        ' не допускает перехода в статус: "Закончено прикрепление раскладок"'
	      	                   WHEN ISNULL(oa.cnt_lo, 0) = 0 THEN 'У эскиза не прикреплено ни одной раскладки.'
	      	                   ELSE NULL
	      	              END
	FROM	(VALUES(@sketch_id))v(sketch_id)   
			LEFT JOIN	Products.Sketch s
				ON	s.sketch_id = v.sketch_id   
			LEFT JOIN	Products.SketchStatus ss
				ON	ss.ss_id = s.ss_id  
			OUTER APPLY (SELECT COUNT(l.layout_id) cnt_lo
			               FROM Manufactory.Layout l WHERE l.base_sketch_id = v.sketch_id) oa
				
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	INSERT INTO @complitying_cons
		(
			completing_id,
			completing_number,
			consumption,
			frame_width
		)
	SELECT	sc.completing_id,
			sc.completing_number,
			oa_lay.consumption,
			oa_lay_fw.frame_width
	FROM	Products.Sketch s   
			INNER JOIN	Products.SketchCompleting sc
				ON	sc.sketch_id = s.sketch_id   
			OUTER APPLY (
			      	SELECT	TOP(1) l.frame_width
			      	FROM	Manufactory.Layout l
			      	WHERE	l.base_sketch_id = s.sketch_id
			      			AND	l.base_completing_id = sc.completing_id
			      			AND	l.base_completing_number = sc.completing_number
			      			AND	l.is_deleted = 0
			      	ORDER BY
			      		l.frame_width ASC
			      ) oa_lay_fw
	OUTER APPLY (
	      	SELECT	AVG(l.base_consumption) consumption
	      	FROM	Manufactory.Layout l
	      	WHERE	l.base_sketch_id = s.sketch_id
	      			AND	l.base_completing_id = sc.completing_id
	      			AND	l.base_completing_number = sc.completing_number
	      			AND	l.is_deleted = 0
	      			AND	l.frame_width = oa_lay_fw.frame_width
	      ) oa_lay
	WHERE s.sketch_id = @sketch_id AND oa_lay.consumption IS NOT NULL
	
	BEGIN TRY
		BEGIN TRANSACTION
		
		UPDATE	s
		SET 	ss_id = @state_appointed_layout_end,
				layout_dt = ISNULL(s.layout_dt, @dt),
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
				AND	s.ss_id = @state_appointed_layout
		
		IF NOT EXISTS (
		   	SELECT	1
		   	FROM	@sketch_output
		   )
		BEGIN
		    SET @with_log = 0
		    RAISERROR('Кто то уже отредактировал статус, перечитайте и попробуйте снова', 16, 1)
		    RETURN
		END
		
		UPDATE	sc
		SET 	consumption = cc.consumption,
				frame_width = cc.frame_width
		FROM	Products.SketchCompleting sc
				INNER JOIN	@complitying_cons cc
					ON	cc.completing_id = sc.completing_id
					AND	cc.completing_number = sc.completing_number
		WHERE	sc.sketch_id = @sketch_id
		
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
				@dt                dt,
				so.status_comment,
				so.plan_site_dt
		FROM	@sketch_output     so
		
		
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