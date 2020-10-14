CREATE PROCEDURE [Manufactory].[Product_CuttingWriteOff_Confirm]
	@data_xml XML,
	@office_id INT,
	@employee_id INT
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @dt DATETIME2(0) = GETDATE()
	DECLARE @data_tab TABLE (product_unic_code INT, spcv_id INT, spcvts_id INT)
	DECLARE @error_text VARCHAR(MAX)
	DECLARE @operation_id INT = 12	
	DECLARE @OutputCodeData TABLE 
	        (product_unic_code INT NOT NULL, pt_id TINYINT, operation_id SMALLINT NOT NULL)
	
	IF NOT EXISTS (
	   	SELECT	1
	   	FROM	Settings.OfficeSetting AS bo
	   	WHERE	bo.office_id = @office_id
	   )
	BEGIN
	    RAISERROR('Филиала с кодом %d не существует.', 16, 1, @office_id)
	    RETURN
	END
	
	INSERT INTO @data_tab
		(
			product_unic_code,
			spcv_id,
			spcvts_id
		)
	SELECT	ml.value('@puc[1]', 'int'),
			spcvt.spcv_id,
			spcvt.spcvts_id
	FROM	@data_xml.nodes('root/det')x(ml)   
			LEFT JOIN	Manufactory.ProductUnicCode puc
				ON	puc.product_unic_code = ml.value('@puc[1]',
			'int')   
			LEFT JOIN	Manufactory.Cutting c
				ON	c.cutting_id = puc.cutting_id   
			LEFT JOIN	Planing.SketchPlanColorVariantTS spcvt
				ON	spcvt.spcvts_id = c.spcvts_id
	
	SELECT	@error_text = CASE 
	      	                   WHEN dt.product_unic_code IS NULL THEN 'Некорректный XML'
	      	                   WHEN dt.product_unic_code IS NOT NULL AND puc.product_unic_code IS NULL THEN 'Продукта с кодом ' + CAST(dt.product_unic_code AS VARCHAR(10)) 
	      	                        + ' не существует'
	      	                   WHEN dt.product_unic_code IS NOT NULL AND puc.operation_id != 11 THEN 'Продукт с кодом ' + CAST(dt.product_unic_code AS VARCHAR(10)) 
	      	                        + ' в статусе "' + o.operation_name + '. списывать крой нельзя.'
	      	                   ELSE NULL
	      	              END
	FROM	@data_tab dt   
			LEFT JOIN	Manufactory.ProductUnicCode puc   
			INNER JOIN	Manufactory.Operation o
				ON	o.operation_id = puc.operation_id
				ON	puc.product_unic_code = dt.product_unic_code
	WHERE	dt.product_unic_code IS NULL
			OR	puc.product_unic_code IS NULL
			OR	puc.operation_id != 10
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	BEGIN TRY
		BEGIN TRANSACTION
		
		UPDATE	puc
		SET 	operation_id = @operation_id,
				puc.dt = @dt
				OUTPUT	INSERTED.product_unic_code,
						INSERTED.pt_id,
						INSERTED.operation_id
				INTO	@OutputCodeData (
						product_unic_code,
						pt_id,
						operation_id
					)
		FROM	Manufactory.ProductUnicCode puc
				INNER JOIN	@data_tab dt
					ON	dt.product_unic_code = puc.product_unic_code
		WHERE	puc.operation_id = 11
		
		IF (
		   	SELECT	COUNT(1)
		   	FROM	@OutputCodeData ocd
		   ) != (
		   	SELECT	COUNT(1)
		   	FROM	@data_tab dt
		   )
		BEGIN
		    RAISERROR('Произошла ошибка, попробуйте снова', 16, 1)
		    RETURN
		END
		
		INSERT INTO Manufactory.ProductOperations
			(
				product_unic_code,
				operation_id,
				office_id,
				employee_id,
				dt,
				is_uniq
			)
		SELECT	ocd.product_unic_code     product_unic_code,
				ocd.operation_id          operation_id,
				@office_id                office_id,
				@employee_id              employee_id,
				@dt                       dt,
				1
		FROM	@OutputCodeData           ocd
		
		MERGE Planing.SketchPlanColorVariantCounter t
			USING (
			      	SELECT	dt.spcv_id,
			      			COUNT(dt.product_unic_code) qty
			      	FROM @data_tab dt
			      	WHERE dt.spcv_id IS NOT NULL
			      	GROUP BY dt.spcv_id
			      ) s
					ON t.spcv_id = s.spcv_id
			WHEN MATCHED THEN 
			     UPDATE	
			     SET 	t.cut_write_off = t.cut_write_off + s.qty,
						t.finished = t.finished + s.qty,
						t.dt_close = CASE WHEN t.cutting_qty <= t.finished + s.qty THEN ISNULL(t.dt_close, @dt) ELSE NULL END 
			WHEN NOT MATCHED THEN 
			     INSERT
			     	(
			     		spcv_id,
			     		cutting_qty,
			     		cut_write_off,
			     		write_off,
			     		packaging,
			     		finished,
			     		dt_close
			     	)
			     VALUES
			     	(
			     		s.spcv_id,
			     		0,
			     		s.qty,
			     		0,
			     		0,
			     		s.qty,
			     		@dt
			     	);	
			     	
			MERGE Planing.SketchPlanColorVariantTSCounter t
			USING (
			      	SELECT	dt.spcvts_id,
			      			COUNT(dt.product_unic_code) qty
			      	FROM @data_tab dt
			      	WHERE dt.spcvts_id IS NOT NULL
			      	GROUP BY dt.spcvts_id
			      ) s
					ON t.spcvts_id = s.spcvts_id
			WHEN MATCHED THEN 
			     UPDATE	
			     SET 	t.cut_write_off = t.cut_write_off + s.qty,
						t.finished = t.finished + s.qty 
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
			     		0,
			     		s.qty,
			     		0,
			     		0,
			     		s.qty
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
		
		RAISERROR('Ошибка %d в строке %d  %s', @esev, @estate, @ErrNum, @Line, @Mess) 
		WITH LOG;
	END CATCH 