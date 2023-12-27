CREATE PROCEDURE [Manufactory].[ProductOperations_Add_v2]
	@product_unic_code INT,
	@operation_id SMALLINT,
	@office_id INT,
	@employee_id INT,
	@packing_box_id INT = NULL,
	@barcode VARCHAR(13) = NULL,
	@product_uniq_data_martix_id INT = NULL,
	@place_id INT = NULL
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @dt DATETIME2(0) = GETDATE()
	
	DECLARE @dt_check_defection DATETIME2(0) = DATEADD(hour, -4, @dt),
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
	DECLARE @is_pacing_operation BIT = 0
	DECLARE @pants_id INT
	DECLARE @fabricator_id int
	
	DECLARE @proc_id INT	
	EXECUTE @proc_id = History.ProcId_GetByName @procid = @@PROCID
	
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
	      	                   --WHEN @operation_id = @to_packaging_operation AND puc.operation_id = @to_packaging_operation THEN 
	      	                   --     'Этот товар уже отправили на упаковку'
	      	                   WHEN @operation_id = @to_packaging_operation AND puc.operation_id NOT IN (@reworking_operation, @special_equipment_operation, @print_label_operation, @launch_of_operation, @to_packaging_operation, @packaging_operation, @modification_operation, @cancellation_operation) THEN 
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
	      	                   --WHEN @operation_id = @modification_operation THEN 'Операция "На стирку" запрещена'
	      	                   WHEN @operation_id IN (@to_packaging_operation, @after_packing_of_se, @repair_and_to_packaging_operation, @packaging_operation) 
	      	                        AND spcvc.create_dt IS NULL THEN 'На это товар не посчитана себестоимость.'
	      	                   WHEN spcv.sew_fabricator_id IS NULL THEN 'Не заполнен производитель цветоварианта'
	      	                   ELSE NULL
	      	              END,
			@spcv_id = spcvt.spcv_id,
			@spcvts_id = spcvt.spcvts_id,
			@sketch_id = sp.sketch_id,
			@pants_id = puc.pants_id,
			@is_pacing_operation = CASE WHEN @operation_id IN (@packaging_operation, @repair_and_to_packaging_operation) THEN 1 ELSE 0 END,
			@fabricator_id = spcv.sew_fabricator_id			
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
			LEFT JOIN Planing.SketchPlanColorVariantCost spcvc
				ON spcvc.spcv_id = spcv.spcv_id
				
	
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	IF EXISTS(
	   	SELECT	1
	   	FROM	Manufactory.ProductOperations po
	   	WHERE	po.product_unic_code = @product_unic_code
	   			AND	(po.operation_id = @operation_id OR po.operation_id = 8)
	   )
	BEGIN
	    SET @is_uniq_operation = 0
	END
	
	IF @is_pacing_operation = 1 AND (@packing_box_id IS NULL OR @barcode IS NULL)
	BEGIN
		RAISERROR('Для упаковки обязательно указывать коробку', 16, 1)
	    RETURN
	END
	
	IF @is_pacing_operation = 1
	BEGIN	
		IF @packing_box_id IS NOT NULL
		BEGIN
			SELECT	@error_text = CASE 
	          						   WHEN pb.packing_box_id IS NULL THEN 'Коробка не валидная, используйте другой шк'
	          						   WHEN pb.close_dt IS NOT NULL THEN 'Коробка ' + CAST(pb.packing_box_id AS VARCHAR(10)) + ' закрыта. Используйте новую коробку.'	
	          						   WHEN oa.othen_fabricator = 1 THEN 'В коробке ' + CAST(pb.packing_box_id AS VARCHAR(10)) + ' уже лежат вещи другого производителя.'       	                   
	          						   ELSE NULL
	          					  END
			FROM	(VALUES(@packing_box_id))v(packing_box_id)   
	    			LEFT JOIN	Logistics.PackingBox pb
	    				ON pb.packing_box_id = v.packing_box_id 
	    			OUTER APPLY (SELECT TOP(1) 1 othen_fabricator
	    			             FROM Logistics.PackingBoxDetail AS pbd 
	    			             INNER JOIN Manufactory.ProductUnicCode AS puc ON puc.product_unic_code = pbd.product_unic_code  								  
									INNER JOIN	Manufactory.Cutting c   
									INNER JOIN	Planing.SketchPlanColorVariantTS spcvt
									INNER JOIN Planing.SketchPlanColorVariant spcv									
										ON spcv.spcv_id = spcvt.spcv_id	
										ON	spcvt.spcvts_id = c.spcvts_id
										ON	c.cutting_id = puc.cutting_id
	    			             WHERE pbd.packing_box_id = v.packing_box_id
	    								AND spcv.sew_fabricator_id != @fabricator_id
	    			
	    			)  oa
	    			
			IF @error_text IS NOT NULL
			BEGIN
				RAISERROR('%s', 16, 1, @error_text)
				RETURN
			END  
		END
		
		IF @product_uniq_data_martix_id IS NOT NULL
		BEGIN
			SELECT	@error_text = CASE 
	      							   WHEN ISNULL(v.product_uniq_data_martix_id, 0) = 0 THEN 'Не указан уникальный код пакета'
	      							   WHEN pudmpu.product_unic_code IS NOT NULL AND pudmpu.product_unic_code != @product_unic_code THEN 
	      									'Этот уникальный код пакета уже связан с изделием TLPR' + CAST(pudmpu.product_unic_code AS VARCHAR(10))
	      							   ELSE NULL
	      						  END
			FROM	(VALUES(@product_uniq_data_martix_id))v(product_uniq_data_martix_id)   
					LEFT JOIN	Manufactory.ProductUniqDataMatrixProductUnic pudmpu
						ON	pudmpu.product_uniq_data_martix_id = v.product_uniq_data_martix_id
				
			IF @error_text IS NOT NULL
			BEGIN
				RAISERROR('%s', 16, 1, @error_text)
				RETURN
			END
		END
		
		IF @place_id IS NOT NULL
		BEGIN 
			SELECT	@error_text = CASE 
	      						   WHEN sp.place_id IS NULL THEN 'Сетки с кодом ' + CAST(v.place_id AS VARCHAR(10)) + ' не существует'
	      						   WHEN sp.is_deleted = 1 THEN 'Сетка ' + sp.place_name + ' удалена.'
	      						   ELSE NULL
	      					  END
			FROM	(VALUES(@place_id))v(place_id)   
					LEFT JOIN	Warehouse.StoragePlace sp
						ON	sp.place_id = v.place_id 
	
			IF @error_text IS NOT NULL
			BEGIN
				RAISERROR('%s', 16, 1, @error_text)
				RETURN
			END
		END
		
		IF @barcode IS NULL 
		BEGIN
			RAISERROR('Ошибка. Отсутвтует баркод.',16,1)
			RETURN
		END
	END
	
	BEGIN TRY
			
		BEGIN TRANSACTION
		
		UPDATE	puc
		SET 	operation_id = CASE 
		    	                    WHEN @operation_id = @to_packaging_operation AND puc.operation_id = @packaging_operation THEN @packaging_operation
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
				   		   	    IN (@reworking_operation, @special_equipment_operation, @print_label_operation, @launch_of_operation, @to_packaging_operation, @packaging_operation, @cancellation_operation, @modification_operation)
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
				@is_uniq_operation		  is_uniq
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
		
		IF @packing_box_id IS NOT NULL AND @is_pacing_operation = 1
		BEGIN
		    
		        MERGE Logistics.PackingBoxDetail t
		        USING (
		              	SELECT	@packing_box_id packing_box_id,
		              			@product_unic_code product_unic_code
		              ) s
		        		ON t.product_unic_code = s.product_unic_code
		        WHEN MATCHED THEN 
		             UPDATE	
		             SET 	t.packing_box_id = s.packing_box_id,
							t.dt = @dt,
							t.employee_id = @employee_id,
							t.barcode = @barcode
		        WHEN NOT MATCHED THEN 
		             INSERT
		             	(
		             		packing_box_id,
		             		product_unic_code,
		             		dt,
		             		employee_id,
		             		barcode
		             	)
		             VALUES
		             	(
		             		s.packing_box_id,
		             		s.product_unic_code,
		             		@dt,
		             		@employee_id,
		             		@barcode
		             	);
		           		           
					INSERT INTO History.PackingBoxDetail
					(
						packing_box_id,
						product_unic_code,
						dt,
						employee_id
					)
					VALUES
					(
						@packing_box_id,
						@product_unic_code,
						@dt,
						@employee_id
					)
				
				IF @place_id IS NOT NULL
				BEGIN
				
					MERGE Warehouse.PackingBoxOnPlace t
					USING (
		      				SELECT	@packing_box_id       packing_box_id,
		      						@place_id        place_id,
		      						@dt              dt,
		      						@employee_id     employee_id
						  ) s
							ON s.packing_box_id = t.packing_box_id
					WHEN MATCHED THEN 
						 UPDATE	
						 SET 	packing_box_id       = s.packing_box_id,
		     					place_id        = s.place_id,
		     					dt              = s.dt,
		     					employee_id     = s.employee_id
					WHEN NOT MATCHED THEN 
						 INSERT
		     				(
		     					packing_box_id,
		     					place_id,
		     					dt,
		     					employee_id
		     				)
						 VALUES
		     				(
		     					s.packing_box_id,
		     					s.place_id,
		     					s.dt,
		     					s.employee_id
		     				) 
						 OUTPUT	INSERTED.packing_box_id,
		     					INSERTED.place_id,
		     					INSERTED.dt,
		     					INSERTED.employee_id,
		     					@proc_id
						 INTO	History.PackingBoxOnPlace (
		     					packing_box_id,
		     					place_id,
		     					dt,
		     					employee_id,
		     					proc_id
		     				);
				END;
		END;
		
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
			
			END;
		
			IF @is_pacing_operation = 1 AND @product_uniq_data_martix_id IS NOT NULL
			BEGIN
				INSERT INTO Manufactory.ProductUniqDataMatrixProductUnic
					(
						product_uniq_data_martix_id,
						product_unic_code
					)
				SELECT	@product_uniq_data_martix_id,
						@product_unic_code
				WHERE	NOT EXISTS(
				     		SELECT	1
				     		FROM	Manufactory.ProductUniqDataMatrixProductUnic pudmpu
				     		WHERE	pudmpu.product_uniq_data_martix_id = @product_uniq_data_martix_id
				     				AND	pudmpu.product_unic_code = @product_unic_code
				     	)
				
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