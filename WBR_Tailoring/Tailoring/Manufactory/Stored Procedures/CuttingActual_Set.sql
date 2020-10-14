CREATE PROCEDURE [Manufactory].[CuttingActual_Set]
	@cutting_id INT,
	@actual_count SMALLINT,
	@employee_id INT,
	@data_xml XML,
	@dt DATETIME2(0) = NULL
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON	
	
	IF @dt IS NULL
	BEGIN
	    SET @dt = GETDATE()
	END
	
	DECLARE @spcv_id INT
	DECLARE @spcvts_id INT
	DECLARE @error_text VARCHAR(MAX)
	
	DECLARE @data TABLE (employee_id INT)
	DECLARE @output_ca TABLE(ca_id INT PRIMARY KEY)
	
	INSERT INTO @data
		(
			employee_id
		)
	SELECT	ml.value('@id', 'int') employee_id
	FROM	@data_xml.nodes('root/empl')x(ml)
	
	IF NOT EXISTS (
	   	SELECT	1
	   	FROM	@data
	   )
	BEGIN
	    RAISERROR('Нельзя добавлять фактический раскрой без сотрудников', 16, 1)
	    RETURN
	END
	
	SELECT	@error_text = CASE 
	      	                   WHEN c.cutting_id IS NULL THEN 'Раскроя с кодом ' + CAST(v.cutting_id AS VARCHAR(10)) + ' не существует'
	      	                   WHEN cov.cost_dt IS NOT NULL THEN 'Уже рассчитана себестоимость, вносить данные нельзя'
	      	                   ELSE NULL
	      	              END,
			@spcv_id = spcvt.spcv_id,
			@spcvts_id = c.spcvts_id
	FROM	(VALUES(@cutting_id))v(cutting_id)   
			LEFT JOIN	Manufactory.Cutting c
				ON	c.cutting_id = v.cutting_id   
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
		VALUES
			(
				@cutting_id,
				@actual_count,
				@dt,
				@employee_id
			)
		
		INSERT INTO Manufactory.CuttingActualEmployee
			(
				ca_id,
				employee_id
			)
		SELECT	o.ca_id,
				d.employee_id
		FROM	@output_ca o   
				CROSS JOIN	@data d
		WHERE	@spcv_id IS NOT NULL
		
		IF @spcv_id IS NOT NULL
		BEGIN
			MERGE Planing.SketchPlanColorVariantCounter t
			USING (
			      	SELECT	@spcv_id spcv_id
			      ) s
					ON t.spcv_id = s.spcv_id
			WHEN MATCHED THEN 
			     UPDATE	
			     SET 	t.cutting_qty = t.cutting_qty + @actual_count
			WHEN NOT MATCHED THEN 
			     INSERT
			     	(
			     		spcv_id,
			     		cutting_qty,
			     		cut_write_off,
			     		write_off,
			     		packaging,
			     		finished
			     	)
			     VALUES
			     	(
			     		s.spcv_id,
			     		@actual_count,
			     		0,
			     		0,
			     		0,
			     		0
			     	);
			     	
			MERGE Planing.SketchPlanColorVariantTSCounter t
			USING (
			      	SELECT	@spcvts_id spcvts_id
			      ) s
					ON t.spcvts_id = s.spcvts_id
			WHEN MATCHED THEN 
			     UPDATE	
			     SET 	t.cutting_qty = t.cutting_qty + @actual_count
			WHEN NOT MATCHED THEN 
			     INSERT
			     	(
			     		spcvts_id,
			     		cutting_qty,
			     		cut_write_off,
			     		write_off,
			     		packaging,
			     		finished
			     	)
			     VALUES
			     	(
			     		s.spcvts_id,
			     		@actual_count,
			     		0,
			     		0,
			     		0,
			     		0
			     	);
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