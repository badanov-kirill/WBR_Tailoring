CREATE PROCEDURE [Products].[Sketch_TechnologSetAndJobAdd]
	@sketch_id INT,
	@technology_employee_id INT,
	@qp_id INT,
	@employee_id INT
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @dt dbo.SECONDSTIME = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	
	IF NOT EXISTS(
	   	SELECT	1
	   	FROM	Products.QueuePriority qp
	   	WHERE	qp.qp_id = @qp_id
	   )
	BEGIN
	    RAISERROR('Приоритетности с кодом (%d) не существует', 16, 1, @qp_id)
	    RETURN
	END
	
	SELECT	@error_text = CASE 
	      	                   WHEN s.sketch_id IS NULL THEN 'Эскиза с номером ' + CAST(v.sketch_id AS VARCHAR(10)) + ' не существует'
	      	                   ELSE NULL
	      	              END
	FROM	(VALUES(@sketch_id))v(sketch_id)   
			LEFT JOIN	Products.Sketch s
				ON	s.sketch_id = v.sketch_id   	
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	BEGIN TRY
		BEGIN TRANSACTION
		
		UPDATE	s
		SET 	s.technology_employee_id = @technology_employee_id,
				s.employee_id = @employee_id,
				s.dt = @dt,
				s.technology_dt = ISNULL(s.technology_dt, @dt)
		FROM	Products.Sketch s
		WHERE	s.sketch_id = @sketch_id
		
		;
		WITH cte_target AS (
			SELECT	stj.stj_id,
					stj.sketch_id,
					stj.create_dt,
					stj.create_employee_id,
					stj.begin_dt,
					stj.begin_employee_id,
					stj.end_dt,
					stj.qp_id
			FROM	Products.SketchTechnologyJob stj
			WHERE	stj.sketch_id = @sketch_id
					AND	stj.end_dt IS NULL
		)
		MERGE cte_target t
		USING (
		      	SELECT	@sketch_id       sketch_id,
		      			@dt              dt,
		      			@employee_id     employee_id,
		      			@qp_id           qp_id
		      ) s
				ON s.sketch_id = t.sketch_id
		WHEN MATCHED THEN 
		     UPDATE	
		     SET 	t.qp_id = s.qp_id
		WHEN NOT MATCHED THEN 
		     INSERT
		     	(
		     		sketch_id,
		     		create_dt,
		     		create_employee_id,
		     		qp_id
		     	)
		     VALUES
		     	(
		     		s.sketch_id,
		     		s.dt,
		     		s.employee_id,
		     		s.qp_id
		     	);
		
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