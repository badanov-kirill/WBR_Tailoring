CREATE PROCEDURE [Products].[SketchTechnologyJob_AddClose]
	@sketch_id INT,
	@employee_id INT
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @dt dbo.SECONDSTIME = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	
	
	SELECT	@error_text = CASE 
	      	                   WHEN s.sketch_id IS NULL THEN 'Эскиза с номером ' + CAST(v.sketch_id AS VARCHAR(10)) + ' не существует'
	      	                   WHEN s.specification_dt IS NULL THEN 'Необходимо сначала загрузить спецификацию'
	      	                   WHEN oa.stj_id IS NULL AND s.technology_dt IS NOT NULL THEN 'На этот эскиз ' + CAST(v.sketch_id AS VARCHAR(10)) +
	      	                        ' уже закрыто задание ' + CONVERT(VARCHAR(20), s.technology_dt, 121)
	      	                   ELSE NULL
	      	              END
	FROM	(VALUES(@sketch_id))v(sketch_id)   
			LEFT JOIN	Products.Sketch s
				ON	s.sketch_id = v.sketch_id   
			OUTER APPLY (
			      	SELECT	TOP(1) stj.stj_id,
			      			stj.begin_employee_id
			      	FROM	Products.SketchTechnologyJob stj
			      	WHERE	stj.sketch_id = @sketch_id
			      			AND	stj.end_dt IS NULL
			      ) oa	
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	BEGIN TRY
		BEGIN TRANSACTION 
		
		UPDATE	s
		SET 	s.technology_dt = @dt
		FROM	Products.Sketch s
		WHERE	s.sketch_id = @sketch_id
				AND	s.technology_dt IS NULL
		
		UPDATE	Products.SketchTechnologyJob
		SET 	end_dt                = @dt,
				begin_employee_id     = ISNULL(begin_employee_id, @employee_id)
		WHERE	sketch_id             = @sketch_id
				AND	end_dt IS NULL
		     			
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