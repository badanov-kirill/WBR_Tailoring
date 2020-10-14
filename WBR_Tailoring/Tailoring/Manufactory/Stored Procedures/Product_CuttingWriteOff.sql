CREATE PROCEDURE [Manufactory].[Product_CuttingWriteOff]
@product_unic_code INT,
	@office_id INT,
	@employee_id INT
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @dt DATETIME2(0) = GETDATE()
	
	DECLARE @reworking_operation SMALLINT = 2,
	        @modification_operation SMALLINT = 4,
	        @special_equipment_operation SMALLINT = 5,
	        @print_label_operation SMALLINT = 7,
	        @launch_of_operation SMALLINT = 9,
	        @repair_and_to_packaging_operation SMALLINT = 10
	
	DECLARE @need_conform BIT = 0
	DECLARE @spcv_id INT
	DECLARE @spcvts_id INT
	
	DECLARE @operation_id SMALLINT = 11 --Подготовлен к списанию кроя
	DECLARE @operation2_id INT = 12	
	DECLARE @OutputCodeData2 TABLE 
	        (product_unic_code INT NOT NULL, pt_id TINYINT, operation_id SMALLINT NOT NULL)
	
	DECLARE @OutputCodeData TABLE 
	        (product_unic_code INT NOT NULL, pt_id TINYINT, operation_id SMALLINT NOT NULL)
	
	DECLARE @OutputData TABLE (po_id INT NOT NULL, product_unic_code INT NOT NULL, operation_id SMALLINT NOT NULL, dt DATETIME2(0) NOT NULL)
	
	IF NOT EXISTS (
	   	SELECT	1
	   	FROM	Settings.OfficeSetting AS bo
	   	WHERE	bo.office_id = @office_id
	   )
	BEGIN
	    RAISERROR('Филиала с кодом %d не существует.', 16, 1, @office_id)
	    RETURN
	END
	
	
	DECLARE @error_text VARCHAR(MAX)
	
	SELECT	@error_text = CASE 
	      	                   WHEN puc.product_unic_code IS NULL THEN 'Такого ШК ' + CAST(v.product_unic_code AS VARCHAR(10)) + ' не существует.'
	      	                   WHEN puc.operation_id NOT IN (@reworking_operation, @modification_operation, @special_equipment_operation, @print_label_operation, @launch_of_operation, @repair_and_to_packaging_operation) THEN 
	      	                        'Текущий статус ШК "' + o.operation_name + '", списывать крой нельзя.'
	      	                   WHEN cov.cost_dt IS NOT NULL THEN 'Посчитана себестоимость, списывать крой нельзя.'
	      	                   ELSE NULL
	      	              END,
			@need_conform     = CASE 
			                     WHEN 100 * (spcvc.cut_write_off + 1) / spcvc.cutting_qty <= 10 THEN 1
			                     ELSE 0
			                END,
			@spcv_id          = spcvt.spcv_id,
			@spcvts_id        = spcvt.spcvts_id
	FROM	(VALUES(@product_unic_code))v(product_unic_code)   
			LEFT JOIN	Manufactory.ProductUnicCode AS puc   
			INNER JOIN	Manufactory.Operation o
				ON	o.operation_id = puc.operation_id   
			INNER JOIN	Manufactory.Cutting c
				ON	c.cutting_id = puc.cutting_id   
			INNER JOIN	Planing.SketchPlanColorVariantTS spcvt
				ON	spcvt.spcvts_id = c.spcvts_id   
			LEFT JOIN	Planing.CoveringDetail cd
				ON	cd.spcv_id = spcvt.spcv_id   
			LEFT JOIN	Planing.Covering cov
				ON	cov.covering_id = cd.covering_id
				ON	puc.product_unic_code = v.product_unic_code   
			LEFT JOIN	Planing.SketchPlanColorVariantCounter spcvc
				ON	spcvc.spcv_id = spcvt.spcv_id
	
	
	
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
		WHERE	puc.product_unic_code = @product_unic_code
				AND	puc.operation_id IN (@reworking_operation, @modification_operation, @special_equipment_operation, @print_label_operation, @launch_of_operation, @repair_and_to_packaging_operation)
		
		IF @@ROWCOUNT = 0
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
			)OUTPUT	INSERTED.po_id,
			 		INSERTED.product_unic_code,
			 		INSERTED.operation_id,
			 		INSERTED.dt
			 INTO	@OutputData (
			 		po_id,
			 		product_unic_code,
			 		operation_id,
			 		dt
			 	)
		SELECT	ocd.product_unic_code     product_unic_code,
				ocd.operation_id          operation_id,
				@office_id                office_id,
				@employee_id              employee_id,
				@dt                       dt,
				1
		FROM	@OutputCodeData           ocd
		
		IF @need_conform = 1
		BEGIN
		    UPDATE	puc
		    SET 	operation_id = @operation2_id,
		    		puc.dt = @dt
		    		OUTPUT	INSERTED.product_unic_code,
		    				INSERTED.pt_id,
		    				INSERTED.operation_id
		    		INTO	@OutputCodeData2 (
		    				product_unic_code,
		    				pt_id,
		    				operation_id
		    			)
		    FROM	Manufactory.ProductUnicCode puc
		    WHERE	puc.product_unic_code = @product_unic_code
		    		AND	puc.operation_id = 11
		    
		    IF @@ROWCOUNT = 0
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
		    SELECT	ocd.product_unic_code product_unic_code,
		    		ocd.operation_id     operation_id,
		    		@office_id           office_id,
		    		@employee_id         employee_id,
		    		@dt                  dt,
		    		1
		    FROM	@OutputCodeData2 ocd
		        	
		        	MERGE Planing.SketchPlanColorVariantCounter t
		        	USING (
		        	      	SELECT	@spcv_id spcv_id,
		        	      			1 qty
		        	      ) s
		        			ON t.spcv_id = s.spcv_id
		        	WHEN MATCHED THEN 
		        	     UPDATE	
		        	     SET 	t.cut_write_off = t.cut_write_off + s.qty,
		        	     		t.finished = t.finished + s.qty,
		        	     		t.dt_close = CASE 
		        	     		                  WHEN t.cutting_qty <= t.finished + s.qty THEN ISNULL(t.dt_close, @dt)
		        	     		                  ELSE NULL
		        	     		             END
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
		          	SELECT	@spcvts_id     spcvts_id,
		          			1              qty
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
		END
		
		COMMIT TRANSACTION
		
		SELECT	od.po_id,
				od.product_unic_code,
				od.operation_id,
				o.operation_name,
				ocd.pt_id                   pt_id,
				pt.pt_name,
				CAST(od.dt AS DATETIME)     dt,
				pa.sa + pan.sa              sa,
				pan.nm_id,
				ISNULL(s.imt_name, sj.subject_name_sf) imt_name,
				b.brand_name,
				ts.ts_name
		FROM	@OutputData od   
				INNER JOIN	@OutputCodeData ocd
					ON	ocd.product_unic_code = od.product_unic_code   
				INNER JOIN	Manufactory.Operation AS o
					ON	o.operation_id = od.operation_id   
				LEFT JOIN	Products.ProductType AS pt
					ON	pt.pt_id = ocd.pt_id   
				INNER JOIN	Manufactory.ProductUnicCode puc
					ON	od.product_unic_code = puc.product_unic_code   
				INNER JOIN	Products.ProdArticleNomenclatureTechSize pants
					ON	pants.pants_id = puc.pants_id   
				INNER JOIN	Products.ProdArticleNomenclature pan
					ON	pan.pan_id = pants.pan_id   
				INNER JOIN	Products.ProdArticle pa
					ON	pa.pa_id = pan.pa_id   
				INNER JOIN	Products.Sketch s
					ON	s.sketch_id = pa.sketch_id   
				INNER JOIN	Products.[Subject] sj
					ON	sj.subject_id = s.subject_id   
				INNER JOIN	Products.Brand b
					ON	b.brand_id = pa.brand_id   
				INNER JOIN	Products.TechSize ts
					ON	ts.ts_id = pants.ts_id
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