CREATE PROCEDURE [Products].[SketchTechnologyJob_Add_v2]
	@sketch_id INT,
	@employee_id INT,
	@comment VARCHAR(200) = NULL
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @dt dbo.SECONDSTIME = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	DECLARE @stj_id INT
	
	SELECT	@error_text = CASE 
	      	                   WHEN s.sketch_id IS NULL THEN 'Эскиза с номером ' + CAST(v.sketch_id AS VARCHAR(10)) + ' не существует'
	      	                   WHEN s.specification_dt IS NULL THEN 'Необходимо сначала загрузить спецификацию'
	      	                   WHEN oa.create_dt IS NOT NULL THEN 'На этот эскиз ' + CAST(v.sketch_id AS VARCHAR(10)) +
	      	                        ' уже есть задание на техпоследовательность, добавленное ' + CONVERT(VARCHAR(20), oa.create_dt, 121) +
	      	                        ' сотрудником с кодом ' +
	      	                        CAST(oa.create_employee_id AS VARCHAR(10))
	      	                   ELSE NULL
	      	              END
	FROM	(VALUES(@sketch_id))v(sketch_id)   
			LEFT JOIN	Products.Sketch s
				ON	s.sketch_id = v.sketch_id   
			OUTER APPLY (
			      	SELECT	TOP(1) stj.create_dt,
			      			stj.create_employee_id
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
				2
			)
		
		IF @comment IS NOT NULL
		BEGIN
		    SET @stj_id = SCOPE_IDENTITY()
		    
		    INSERT INTO Products.SketchTechnologyJobComment
		    	(
		    		stj_id,
		    		comment
		    	)
		    VALUES
		    	(
		    		@stj_id,
		    		@comment
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
		
		RAISERROR('Ошибка %d в строке %d  %s', @esev, @estate, @ErrNum, @Line, @Mess) WITH LOG;
	END CATCH 