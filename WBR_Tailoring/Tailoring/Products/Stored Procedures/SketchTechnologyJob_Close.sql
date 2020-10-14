CREATE PROCEDURE [Products].[SketchTechnologyJob_Close]
	@stj_id INT,
	@employee_id INT
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @dt dbo.SECONDSTIME = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	DECLARE @sketch_id INT
	
	SELECT	@error_text = CASE 
	      	                   WHEN stj.stj_id IS NULL THEN 'Задания на написание техпоследовательности с кодом ' + CAST(v.stj_id AS VARCHAR(10)) +
	      	                        ' не существует.'
	      	                   WHEN stj.begin_employee_id != @employee_id THEN 'Задание на написание техпоследовательности с кодом ' + CAST(v.stj_id AS VARCHAR(10)) 
	      	                        +
	      	                        ' взято в работу другим сотрудником(' + CAST(stj.begin_employee_id AS VARCHAR(10)) + ').'
	      	                   WHEN stj.end_dt IS NOT NULL THEN 'Задание на написание техпоследовательности с кодом ' + CAST(v.stj_id AS VARCHAR(10)) +
	      	                        ' уже выполнено.'
	      	                   ELSE NULL
	      	              END,
			@sketch_id = stj.sketch_id
	FROM	(VALUES(@stj_id))v(stj_id)   
			LEFT JOIN	Products.SketchTechnologyJob stj
				ON	stj.stj_id = v.stj_id
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	BEGIN TRY
		BEGIN TRANSACTION 
		UPDATE	Products.SketchTechnologyJob
		SET 	end_dt = @dt
		WHERE	stj_id = @stj_id
				AND	end_dt IS NULL
		
		UPDATE	s
		SET 	s.technology_dt = @dt
		FROM	Products.Sketch s
		WHERE	s.sketch_id = @sketch_id
				AND	s.technology_dt IS NULL
		
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
		
		RAISERROR('Ошибка %d в строке %d  %s', @esev, @estate, @ErrNum, @Line, @Mess) 
		WITH LOG;
	END CATCH