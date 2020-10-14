CREATE PROCEDURE [Manufactory].[CuttingActual_Storno]
	@ca_id INT,
	@employee_id INT,
	@dt dbo.SECONDSTIME = NULL
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON	
	DECLARE @actual_count SMALLINT
	DECLARE @spcv_id INT
	DECLARE @spcvts_id INT
	DECLARE @error_text VARCHAR(MAX)
	
	IF @dt IS NULL
	BEGIN
	    SET @dt = GETDATE()
	END
	
	DECLARE @output_ca TABLE(ca_id INT PRIMARY KEY)
	
	SELECT	@error_text = CASE 
	      	                   WHEN ca.ca_id IS NULL THEN 'Записи с кодом ' + CAST(v.ca_id AS VARCHAR(10)) + ' не существует'
	      	                   WHEN cov.cost_dt IS NOT NULL THEN 'Уже рассчитана себестоимость, вносить данные нельзя'
	      	                   ELSE NULL
	      	              END,
			@spcv_id = spcvt.spcv_id,
			@spcvts_id = spcvt.spcvts_id,
			@actual_count = ca.actual_count
	FROM	(VALUES(@ca_id))v(ca_id)  
			LEFT JOIN Manufactory.CuttingActual ca 
				ON ca.ca_id = v.ca_id 
			LEFT JOIN	Manufactory.Cutting c
				ON	c.cutting_id = ca.cutting_id   
			LEFT JOIN	Planing.SketchPlanColorVariantTS spcvt   
			LEFT JOIN	Planing.SketchPlanColorVariant spcv
				ON	spcv.spcv_id = spcvt.spcv_id   
			LEFT JOIN	Planing.CoveringDetail cd
				ON	cd.spcv_id = spcv.spcv_id   
			LEFT JOIN	Planing.Covering cov
				ON	cov.covering_id = cd.covering_id
				ON	spcvt.spcvts_id = c.spcvts_id
	
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	BEGIN TRY
		BEGIN TRANSACTION
		
		INSERT INTO Manufactory.CuttingActual
		  (
		    cutting_id,
		    actual_count,
		    dt,
		    employee_id
		  )OUTPUT	INSERTED.ca_id
		   INTO	@output_ca (
		   		ca_id
		   	)
		SELECT	ca.cutting_id,
				-ca.actual_count,
				@dt,
				@employee_id
		FROM	Manufactory.CuttingActual ca
		WHERE	ca.ca_id = @ca_id
		
		INSERT INTO Manufactory.CuttingActualEmployee
		  (
		    ca_id,
		    employee_id
		  )
		SELECT	o.ca_id,
				cae.employee_id
		FROM	Manufactory.CuttingActual ca   
				INNER JOIN	Manufactory.CuttingActualEmployee cae
					ON	cae.ca_id = ca.ca_id   
				CROSS JOIN	@output_ca o
		WHERE	ca.ca_id = @ca_id
		
		IF @spcv_id IS NOT NULL
		BEGIN
		    UPDATE	Planing.SketchPlanColorVariantCounter
		    SET 	cutting_qty     = cutting_qty - @actual_count
		    WHERE	spcv_id         = @spcv_id
		    
		    UPDATE	Planing.SketchPlanColorVariantTSCounter
		    SET 	cutting_qty     = cutting_qty - @actual_count
		    WHERE	spcvts_id         = @spcvts_id
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