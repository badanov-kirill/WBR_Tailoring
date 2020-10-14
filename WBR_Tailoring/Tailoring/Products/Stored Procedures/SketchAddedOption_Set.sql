CREATE PROCEDURE [Products].[SketchAddedOption_Set]
	@sketch_id INT,
	@ao_id INT,
	@ao_value DECIMAL(9, 2),
	@employee_id INT,
	@si_id INT
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	DECLARE @dt dbo.SECONDSTIME = GETDATE()
	
	IF NOT EXISTS(
	   	SELECT	1
	   	FROM	Products.Sketch s
	   	WHERE	s.sketch_id = @sketch_id
	   )
	BEGIN
	    RAISERROR('Эскиза с кодом %d не существует', 16, 1, @sketch_id)
	    RETURN
	END
	
	IF NOT EXISTS (
	   	SELECT	1
	   	FROM	Products.AddedOption ao
	   	WHERE	ao.ao_id = @ao_id
	   )
	BEGIN
	    RAISERROR('Допопции с кодом %d не существует', 16, 1, @ao_id)
	    RETURN
	END
	
	IF @si_id IS NOT NULL
	   AND NOT EXISTS (
	       	SELECT	1
	       	FROM	Products.SI s
	       	WHERE	s.si_id = @si_id
	       )
	BEGIN
	    RAISERROR('Еденицы измерения с кодом %d не существует', 16, 1, @si_id)
	    RETURN
	END
	
	BEGIN TRY
		BEGIN TRANSACTION 
		;
		WITH cte_target AS
		(
			SELECT	sao.sketch_id,
					sao.ao_id,
					sao.employee_id,
					sao.dt,
					sao.ao_value,
					sao.si_id
			FROM	Products.SketchAddedOption sao
			WHERE	sao.sketch_id = @sketch_id
					AND	sao.ao_id = @ao_id
		)
		MERGE cte_target t
		USING (
		      	SELECT	@sketch_id     sketch_id,
		      			@ao_id         ao_id,
		      			@ao_value      ao_value
		      ) s
				ON s.sketch_id = t.sketch_id
				AND s.ao_id = t.ao_id
		WHEN MATCHED AND s.ao_value = 0 THEN 
		     DELETE	
		WHEN MATCHED AND s.ao_value != 0 THEN 
		     UPDATE	
		     SET 	employee_id     = @employee_id,
		     		dt              = @dt,
		     		ao_value        = CASE 
		     		                WHEN @si_id IS NULL THEN NULL
		     		                ELSE s.ao_value
		     		           END,
		     		si_id           = @si_id
		WHEN NOT MATCHED AND s.ao_value != 0 THEN 
		     INSERT
		     	(
		     		sketch_id,
		     		ao_id,
		     		employee_id,
		     		dt,
		     		ao_value,
		     		si_id
		     	)
		     VALUES
		     	(
		     		s.sketch_id,
		     		s.ao_id,
		     		@employee_id,
		     		@dt,
		     		s.ao_value,
		     		@si_id
		     	);
		
		IF @ao_value != 0
		BEGIN
		    UPDATE	paao
		    SET 	ao_value        = CASE 
		        	                WHEN @si_id IS NULL THEN NULL
		        	                ELSE @ao_value
		        	           END,
		    		si_id           = @si_id,
		    		employee_id     = @employee_id,
		    		dt              = @dt
		    FROM	Products.Sketch s
		    		INNER JOIN	Products.ProdArticle pa
		    			ON	pa.sketch_id = s.sketch_id
		    		INNER JOIN	Products.ProdArticleAddedOption paao
		    			ON	paao.pa_id = pa.pa_id
		    WHERE	s.sketch_id = @sketch_id
		    		AND	paao.ao_id = @ao_id
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
		
		RAISERROR('Ошибка %d в строке %d  %s', @esev, @estate, @ErrNum, @Line, @Mess) 
		WITH LOG;
	END CATCH