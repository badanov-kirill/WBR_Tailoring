﻿CREATE PROCEDURE [Manufactory].[ProductOperations_Add]
	@product_unic_code INT,
	@operation_id SMALLINT,
	@office_id INT,
	@employee_id INT,
	@dt dbo.SECONDSTIME = NULL,
	@transfer_box_id BIGINT = NULL
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	IF @dt IS NULL
	BEGIN
	    SET @dt = GETDATE()
	END
	
	DECLARE @dt_check_defection dbo.SECONDSTIME = DATEADD(hour, -4, @dt),
	        @to_packaging_operation SMALLINT = 1,
	        @reworking_operation SMALLINT = 2,
	        @cancellation_operation SMALLINT = 3,
	        @modification_operation SMALLINT = 4,
	        @special_equipment_operation SMALLINT = 5,
	        @after_packing_of_se SMALLINT = 6,
	        @print_label_operation SMALLINT = 7,
	        @packaging_operation SMALLINT = 8,
	        @launch_of_operation SMALLINT = 9,
	        @repair_and_to_packaging_operation SMALLINT = 10
	
	DECLARE @spcv_id INT
	DECLARE @spcvts_id INT
	DECLARE @sketch_id INT
	DECLARE @is_uniq_operation BIT = 1
	DECLARE @deadline_package_dt DATE 
	
	DECLARE @OutputCodeData TABLE 
	        (product_unic_code INT NOT NULL, pt_id TINYINT, operation_id SMALLINT NOT NULL)
	
	DECLARE @OutputData TABLE (po_id INT NOT NULL, product_unic_code INT NOT NULL, operation_id SMALLINT NOT NULL, dt dbo.SECONDSTIME NOT NULL)
	
	IF NOT EXISTS (
	   	SELECT	1
	   	FROM	Settings.OfficeSetting AS bo
	   	WHERE	bo.office_id = @office_id
	   )
	BEGIN
	    RAISERROR('Филиала с кодом %d не существует.', 16, 1, @office_id)
	    RETURN
	END
	
	IF NOT EXISTS (
	   	SELECT	1
	   	FROM	Manufactory.Operation AS o
	   	WHERE	o.operation_id = @operation_id
	   )
	BEGIN
	    RAISERROR('Операции с кодом %d не существует.', 16, 1, @operation_id)
	    RETURN
	END
	
	DECLARE @error_text VARCHAR(MAX)
	
	SELECT	@error_text = CASE 
	      	                   WHEN puc.product_unic_code IS NULL THEN 'Такого ШК ' + CAST(v.product_unic_code AS VARCHAR(10)) + ' не существует.'
	      	                   WHEN @operation_id = @print_label_operation THEN 'Печать Составника/Уходника делается один раз и уже произведена'
	      	                   WHEN @operation_id = @launch_of_operation AND puc.operation_id != @print_label_operation THEN 
	      	                        'Запус в производства возможен только после печати, сейчас статус ' + o.operation_name
	      	                   WHEN puc.operation_id IN (@reworking_operation, @modification_operation)
	      	                        AND puc.dt > @dt_check_defection THEN 'Нельзя проверять одну вещь чаще одного раза в 4 часа'
	      	                   WHEN @operation_id IN (@reworking_operation, @cancellation_operation, @modification_operation) 
	      	                        AND puc.operation_id IN (@to_packaging_operation, @after_packing_of_se) THEN 
	      	                        'Нельзя отбраковать отправленную на упаковку вещь'
	      	                   WHEN @operation_id IN (@reworking_operation, @cancellation_operation, @modification_operation) 
	      	                        AND puc.operation_id NOT IN (@reworking_operation, @special_equipment_operation, @print_label_operation, @modification_operation, @launch_of_operation, @packaging_operation) THEN 
	      	                        'Этот товар в статусе ' + o.operation_name + ' . Отбраковывать нельзя'
	      	                   WHEN @operation_id = @special_equipment_operation AND puc.operation_id NOT IN (@reworking_operation, @print_label_operation, @modification_operation, @launch_of_operation) THEN 
	      	                        'Этот товар в статусе ' + o.operation_name + ' . Отправлять на спецоборудование нельзя'
	      	                   WHEN @operation_id = @to_packaging_operation AND puc.operation_id = @to_packaging_operation THEN 
	      	                        'Этот товар уже отправили на упаковку'
	      	                   WHEN @operation_id = @to_packaging_operation AND puc.operation_id NOT IN (@reworking_operation, @special_equipment_operation, @print_label_operation, @launch_of_operation) THEN 
	      	                        'Этот товар в статусе ' + o.operation_name + ' . Отправлять на упаковку нельзя'
	      	                   WHEN @operation_id = @packaging_operation AND puc.operation_id NOT IN (@to_packaging_operation, @after_packing_of_se, @packaging_operation, @repair_and_to_packaging_operation) THEN 
	      	                        'Этот товар в статусе ' + o.operation_name + ' . Упаковывать можно только отправленный на упаковку товар'
	      	                   WHEN @operation_id = @repair_and_to_packaging_operation AND puc.operation_id NOT IN (@cancellation_operation, @modification_operation, @reworking_operation) THEN 
	      	                        'Этот товар в статусе ' + o.operation_name + ' . Устанавливать статус "отремонтирован" нельзя'
	      	                   WHEN @operation_id IN (@to_packaging_operation, @after_packing_of_se, @repair_and_to_packaging_operation, @packaging_operation) 
	      	                        AND ISNULL(pan.price_ru, 0) = 0 THEN 'На этот товар нет цены.'
	      	                   WHEN @operation_id NOT IN (@to_packaging_operation, @reworking_operation, @cancellation_operation, @modification_operation, @special_equipment_operation, 
	      	                                             @after_packing_of_se, @print_label_operation, @packaging_operation, @launch_of_operation, @repair_and_to_packaging_operation) THEN 
	      	                        'Операция с кодом ' + CAST(@operation_id AS VARCHAR(10)) + ' не допускается в этой обработке'
	      	                   ELSE NULL
	      	              END,
			@spcv_id = spcvt.spcv_id,
			@spcvts_id = spcvt.spcvts_id,
			@sketch_id = sp.sketch_id,
			@deadline_package_dt = ISNULL(spcv.deadline_package_dt, DATEADD(DAY, -7, sp.plan_sew_dt))
	FROM	(VALUES(@product_unic_code))v(product_unic_code)   
			LEFT JOIN	Manufactory.ProductUnicCode AS puc   
			INNER JOIN	Manufactory.Operation o
				ON	o.operation_id = puc.operation_id   
			INNER JOIN	Products.ProdArticleNomenclatureTechSize pants
				ON	pants.pants_id = puc.pants_id   
			INNER JOIN	Products.ProdArticleNomenclature pan
				ON	pan.pan_id = pants.pan_id
				ON	puc.product_unic_code = v.product_unic_code   
			LEFT JOIN	Manufactory.Cutting c   
			INNER JOIN	Planing.SketchPlanColorVariantTS spcvt
			INNER JOIN Planing.SketchPlanColorVariant spcv
			INNER JOIN Planing.SketchPlan sp
				ON sp.sp_id = spcv.sp_id
				ON spcv.spcv_id = spcvt.spcv_id	
				ON	spcvt.spcvts_id = c.spcvts_id
				ON	c.cutting_id = puc.cutting_id
				
	
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	IF EXISTS(
	   	SELECT	1
	   	FROM	Manufactory.ProductOperations po
	   	WHERE	po.product_unic_code = @product_unic_code
	   			AND	po.operation_id = @operation_id
	   )
	BEGIN
	    SET @is_uniq_operation = 0
	END
	
	IF (@operation_id = @packaging_operation OR @operation_id = @repair_and_to_packaging_operation) AND @transfer_box_id IS NULL
	BEGIN
		RAISERROR('Для упаковки обязательно указывать коробку', 16, 1)
	    RETURN
	END
	
	IF @transfer_box_id IS NOT NULL
	   AND (@operation_id = @packaging_operation OR @operation_id = @repair_and_to_packaging_operation)
	BEGIN
	    SELECT	@error_text = CASE 
	          	                   WHEN tb.transfer_box_id IS NULL THEN 'Коробка не валидная, используйте другой шк'
	          	                   WHEN tb.transfer_box_id IS NULL AND tb.plan_shipping_dt IS NULL AND tbs.transfer_box_id IS NULL THEN 
	          	                        'У коробки не заполнена плановая дата отгрузки'
	          	                   WHEN tbs.transfer_box_id IS NOT NULL AND oas.spcv_id IS NULL THEN 'Эта спецкоробка не предназначена для этого изделия'
	          	                   WHEN tbs.transfer_box_id IS NULL AND (@deadline_package_dt > DATEADD(DAY, 7, tb.plan_shipping_dt) OR @deadline_package_dt < DATEADD(DAY, -7, tb.plan_shipping_dt)) THEN 
	          	                        'Дата сайта ' + CAST(@deadline_package_dt AS VARCHAR(20)) + ' не должна отличаться от плановой даты отгрузки коробки ' + 
	          	                        CAST(tb.plan_shipping_dt AS VARCHAR(20)) + ' более 7 дней.'
	          	                   ELSE NULL
	          	              END
	    FROM	(VALUES(@transfer_box_id))v(transfer_box_id)   
	    		LEFT JOIN	Logistics.TransferBox tb
	    			ON	tb.transfer_box_id = v.transfer_box_id   
	    		LEFT JOIN	Logistics.TransferBoxSpecial tbs
	    			ON	tbs.transfer_box_id = v.transfer_box_id   
	    		OUTER APPLY (
	    		      	SELECT	TOP(1) tbss.spcv_id
	    		      	FROM	Logistics.TransferBoxSpecialSPCV tbss
	    		      	WHERE	tbss.transfer_box_id = tbs.transfer_box_id
	    		      			AND	tbss.spcv_id = @spcv_id
	    		      ) oas
	END
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	BEGIN TRY
	
		--IF @transfer_box_id IS NOT NULL
		--BEGIN
		--    INSERT INTO Logistics.TransferBox
		--    	(
		--    		transfer_box_id,
		--    		create_dt,
		--    		create_employee_id
		--    	)
		--    SELECT	@transfer_box_id,
		--    		@dt,
		--    		@employee_id
		--    WHERE	NOT EXISTS (
		--         		SELECT	1
		--         		FROM	Logistics.TransferBox tb
		--         		WHERE	tb.transfer_box_id = @transfer_box_id
		--    )
		--END
		
		BEGIN TRANSACTION
		
		UPDATE	puc
		SET 	operation_id = CASE 
		    	                    WHEN operation_id = @special_equipment_operation AND @operation_id = @to_packaging_operation THEN @after_packing_of_se
		    	                    ELSE @operation_id
		    	               END,
				puc.dt = @dt,
				puc.packing_dt = CASE 
				                      WHEN @operation_id IN (@packaging_operation, @to_packaging_operation, @cancellation_operation, @modification_operation, @after_packing_of_se) 
				                           AND puc.packing_dt IS NULL THEN @dt
				                      ELSE puc.packing_dt
				                 END
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
				AND	NOT (
				   		(puc.operation_id IN (@reworking_operation, @cancellation_operation, @modification_operation) AND puc.dt > @dt_check_defection)
				   		OR (@operation_id = @launch_of_operation AND puc.operation_id != @print_label_operation)
				   		OR (
				   		   	@operation_id 
				   		   	IN (@reworking_operation, @cancellation_operation, @modification_operation)
				   		   	AND puc.operation_id NOT 
				   		   	    IN (@reworking_operation, @special_equipment_operation, @print_label_operation, @modification_operation, @special_equipment_operation, @launch_of_operation, @packaging_operation)
				   		   )
				   		OR (
				   		   	@operation_id = @special_equipment_operation
				   		   	AND puc.operation_id NOT 
				   		   	    IN (@reworking_operation, @print_label_operation, @modification_operation, @launch_of_operation)
				   		   )
				   		OR (
				   		   	@operation_id = @to_packaging_operation
				   		   	AND puc.operation_id NOT 
				   		   	    IN (@reworking_operation, @special_equipment_operation, @print_label_operation, @launch_of_operation)
				   		   )
				   		OR (
				   		   	@operation_id = @packaging_operation
				   		   	AND puc.operation_id NOT 
				   		   	    IN (@to_packaging_operation, @after_packing_of_se, @packaging_operation, @repair_and_to_packaging_operation)
				   		   )
				   		OR (@operation_id = @repair_and_to_packaging_operation AND puc.operation_id NOT IN (@cancellation_operation, @modification_operation, @reworking_operation))
				   	)
		
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
				@is_uniq_operation
		FROM	@OutputCodeData           ocd
		
		UPDATE	Planing.SketchPlanColorVariant
		SET 	fist_package_dt     = @dt
		WHERE	spcv_id             = @spcv_id
				AND	fist_package_dt IS NULL
				AND	@operation_id IN (@packaging_operation, @repair_and_to_packaging_operation)
		
		UPDATE	Products.Sketch
		SET 	fist_package_dt     = @dt
		WHERE	sketch_id           = @sketch_id
				AND	fist_package_dt IS NULL
				AND	@operation_id IN (@packaging_operation, @repair_and_to_packaging_operation)
		
		IF @transfer_box_id IS NOT NULL
		BEGIN
		    
		    
		    IF @operation_id = @packaging_operation OR @operation_id = @repair_and_to_packaging_operation
		    BEGIN
		        MERGE Logistics.TransferBoxDetail t
		        USING (
		              	SELECT	@transfer_box_id transfer_box_id,
		              			@product_unic_code product_unic_code
		              ) s
		        		ON t.product_unic_code = s.product_unic_code
		        WHEN MATCHED THEN 
		             UPDATE	
		             SET 	t.transfer_box_id = s.transfer_box_id
		        WHEN NOT MATCHED THEN 
		             INSERT
		             	(
		             		transfer_box_id,
		             		product_unic_code
		             	)
		             VALUES
		             	(
		             		s.transfer_box_id,
		             		s.product_unic_code
		             	);
		    END
		END
		
		IF @spcv_id IS NOT NULL AND @is_uniq_operation = 1 AND @operation_id IN (@packaging_operation, @cancellation_operation)
		BEGIN
			MERGE Planing.SketchPlanColorVariantCounter t
			USING (
			      	SELECT	@spcv_id spcv_id
			      ) s
					ON t.spcv_id = s.spcv_id
			WHEN MATCHED THEN 
			     UPDATE	
			     SET 	packaging     = CASE 
			         	                 WHEN @operation_id = @packaging_operation THEN t.packaging + 1
			         	                 ELSE t.packaging
			         	            END,
			     		write_off     = CASE 
			     		                 WHEN @operation_id = @cancellation_operation THEN t.write_off + 1
			     		                 ELSE t.write_off
			     		            END,
			     		finished      = CASE 
			     		                WHEN @operation_id  IN (@cancellation_operation, @packaging_operation) THEN t.finished + 1
			     		                ELSE t.finished
			     		           END,
			     		dt_close      = CASE 
			     		                WHEN t.cutting_qty <= CASE 
			     		                                           WHEN @operation_id  IN (@cancellation_operation, @packaging_operation) THEN t.finished + 1
			     		                                           ELSE t.finished
			     		                                      END THEN ISNULL(t.dt_close, @dt)
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
			     		0,
			     		CASE 
			     		     WHEN @operation_id = @cancellation_operation THEN 1
			     		     ELSE 0
			     		END,
			     		CASE 
			     		     WHEN @operation_id = @packaging_operation THEN 1
			     		     ELSE 0
			     		END,
			     		CASE 
			     		     WHEN @operation_id IN (@cancellation_operation, @packaging_operation) THEN 1
			     		     ELSE 0
			     		END,
			     		@dt
			     	);
			     	
			MERGE Planing.SketchPlanColorVariantTSCounter t
			USING (
			      	SELECT	@spcvts_id spcvts_id
			      ) s
					ON t.spcvts_id = s.spcvts_id
			WHEN MATCHED THEN 
			     UPDATE	
			     SET 	packaging     = CASE 
			         	                 WHEN @operation_id = @packaging_operation THEN t.packaging + 1
			         	                 ELSE t.packaging
			         	            END,
			     		write_off     = CASE 
			     		                 WHEN @operation_id = @cancellation_operation THEN t.write_off + 1
			     		                 ELSE t.write_off
			     		            END,
			     		finished      = CASE 
			     		                WHEN @operation_id  IN (@cancellation_operation, @packaging_operation) THEN t.finished + 1
			     		                ELSE t.finished
			     		           END			     		
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
			     		0,
			     		CASE 
			     		     WHEN @operation_id = @cancellation_operation THEN 1
			     		     ELSE 0
			     		END,
			     		CASE 
			     		     WHEN @operation_id = @packaging_operation THEN 1
			     		     ELSE 0
			     		END,
			     		CASE 
			     		     WHEN @operation_id IN (@cancellation_operation, @packaging_operation) THEN 1
			     		     ELSE 0
			     		END
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