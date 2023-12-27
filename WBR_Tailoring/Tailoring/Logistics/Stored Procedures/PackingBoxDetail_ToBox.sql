CREATE PROCEDURE [Logistics].[PackingBoxDetail_ToBox]
	@src_packing_box_id INT,
	@dst_packing_box_id INT,
	@employee_id INT,
	@data_tab dbo.List READONLY
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @dt DATETIME2(0) = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	DECLARE @update_data TABLE (pbd_id INT)
	DECLARE @output_data TABLE (packing_box_id INT, product_unic_code INT)
	DECLARE @place_id INT
	DECLARE @proc_id INT
	EXECUTE @proc_id = History.ProcId_GetByName @procid = @@PROCID	
	
	SELECT	@error_text = CASE 
	      	                   WHEN pb.packing_box_id IS NULL THEN 'Коробка не валидная, используйте другой шк'
	      	                   ELSE NULL
	      	              END
	FROM	(VALUES(@src_packing_box_id))v(packing_box_id)   
			LEFT JOIN	Logistics.PackingBox pb
				ON	pb.packing_box_id = v.packing_box_id   
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END  
	
	SELECT	@error_text = CASE 
	      	                   WHEN pb.packing_box_id IS NULL THEN 'Коробка не валидная, используйте другой шк'
	      	                   ELSE NULL
	      	              END
	FROM	(VALUES(@dst_packing_box_id))v(packing_box_id)   
			LEFT JOIN	Logistics.PackingBox pb
				ON	pb.packing_box_id = v.packing_box_id   
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END  
	
	SELECT	@error_text = CASE 
	      	                   WHEN pbd.product_unic_code IS NULL THEN 'Идентификатора размера цветоварианта ' + CAST(dt.id AS VARCHAR(20)) +
	      	                        ' нет в коробке источнике.'
	      	                   ELSE NULL
	      	              END
	FROM	@data_tab dt   
			LEFT JOIN	Products.ProdArticleNomenclatureTechSize pants   
			INNER JOIN	Manufactory.ProductUnicCode puc
				ON	puc.pants_id = pants.pants_id   
			INNER JOIN	Logistics.PackingBoxDetail pbd
				ON	pbd.product_unic_code = puc.product_unic_code
				AND	pbd.packing_box_id = @src_packing_box_id
				ON	pants.pants_id = dt.id
	WHERE pbd.product_unic_code IS NULL
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END  
	
	
	SET @error_text = 'После перемещения товаров, в коробке окажутся артикула с различающимися баркодами ' +(
    		SELECT	CHAR(10) + 'Арт: ' + v.sa + v.sanm + ' ' + v.ts_name + ', баркоды: ' + v.barcode1 + ' и ' + v.barcode2
    		FROM	(SELECT	TOP(3) pa.sa         sa,
    	    	 			pan.sa               sanm,
    	    	 			ts.ts_name,
    	    	 			MAX(pbd.barcode)     barcode1,
    	    	 			MIN(pbd.barcode)     barcode2
    	    		 FROM	@data_tab dt   
    	    	 			INNER JOIN	Products.ProdArticleNomenclatureTechSize pants   
    	    	 			INNER JOIN	Products.TechSize ts
    	    	 				ON	ts.ts_id = pants.ts_id   
    	    	 			INNER JOIN	Products.ProdArticleNomenclature pan
    	    	 				ON	pan.pan_id = pants.pan_id   
    	    	 			INNER JOIN	Products.ProdArticle pa
    	    	 				ON	pa.pa_id = pan.pa_id   
    	    	 			INNER JOIN	Manufactory.ProductUnicCode puc
    	    	 				ON	puc.pants_id = pants.pants_id   
    	    	 			INNER JOIN	Logistics.PackingBoxDetail pbd
    	    	 				ON	pbd.product_unic_code = puc.product_unic_code
    	    	 				AND	pbd.packing_box_id IN (@src_packing_box_id, @dst_packing_box_id)
    	    	 				ON	pants.pants_id = dt.id
    	    		 GROUP BY
    	    	 		pa.sa,
    	    	 		pan.sa,
    	    	 		ts.ts_name
    	    		 HAVING
    	    	 		COUNT(DISTINCT pbd.barcode) > 1)v
    		FOR XML	PATH('')
		)

	IF @error_text IS NOT NULL
	BEGIN
		RAISERROR('%s', 16, 1, @error_text)
		RETURN
	END
		

	SELECT @error_text = string_agg(
	           'После переноса в коробке ' + CAST(vg.packing_box_id AS VARCHAR(10)) + 
	           ' будут вещи разных производителей',
	           '; '
	       )
	FROM   (
	           SELECT v.packing_box_id,
	                  COUNT(DISTINCT ISNULL(v.sew_fabricator_id, 1)) cnt_fab
	           FROM   (
	                      SELECT @dst_packing_box_id packing_box_id,
	                             spcv.sew_fabricator_id
	                      FROM   @data_tab dt
	                             LEFT JOIN Products.ProdArticleNomenclatureTechSize pants
	                             INNER JOIN Manufactory.ProductUnicCode puc
	                                  ON  puc.pants_id = pants.pants_id
	                             INNER JOIN Logistics.PackingBoxDetail pbd
	                                  ON  pbd.product_unic_code = puc.product_unic_code
	                                  AND pbd.packing_box_id = @src_packing_box_id
	                                  ON  pants.pants_id = dt.id
	                             INNER JOIN Manufactory.Cutting c
	                             INNER JOIN Planing.SketchPlanColorVariantTS spcvt
	                             INNER JOIN Planing.SketchPlanColorVariant spcv
	                                  ON  spcv.spcv_id = spcvt.spcv_id
	                                  ON  spcvt.spcvts_id = c.spcvts_id
	                                  ON  c.cutting_id = puc.cutting_id
	                      UNION ALL
	                      SELECT pbd.packing_box_id,
	                             spcv.sew_fabricator_id
	                      FROM   Logistics.PackingBoxDetail AS pbd
	                             INNER JOIN Manufactory.ProductUnicCode AS puc
	                                  ON  puc.product_unic_code = pbd.product_unic_code
	                             INNER JOIN Manufactory.Cutting c
	                             INNER JOIN Planing.SketchPlanColorVariantTS spcvt
	                             INNER JOIN Planing.SketchPlanColorVariant spcv
	                                  ON  spcv.spcv_id = spcvt.spcv_id
	                                  ON  spcvt.spcvts_id = c.spcvts_id
	                                  ON  c.cutting_id = puc.cutting_id
	                      WHERE  pbd.packing_box_id = @src_packing_box_id
	                             AND NOT EXISTS(
	                                     SELECT NULL
	                                     FROM   @data_tab dt
	                                            LEFT JOIN Products.ProdArticleNomenclatureTechSize pants
	                                            INNER JOIN Manufactory.ProductUnicCode puc
	                                                 ON  puc.pants_id = pants.pants_id
	                                                 ON  pants.pants_id = dt.id
	                                     WHERE  pbd.product_unic_code = puc.product_unic_code
	                                 )
	                      UNION ALL
	                      SELECT pbd.packing_box_id,
	                             spcv.sew_fabricator_id
	                      FROM   Logistics.PackingBoxDetail AS pbd
	                             INNER JOIN Manufactory.ProductUnicCode AS puc
	                                  ON  puc.product_unic_code = pbd.product_unic_code
	                             INNER JOIN Manufactory.Cutting c
	                             INNER JOIN Planing.SketchPlanColorVariantTS spcvt
	                             INNER JOIN Planing.SketchPlanColorVariant spcv
	                                  ON  spcv.spcv_id = spcvt.spcv_id
	                                  ON  spcvt.spcvts_id = c.spcvts_id
	                                  ON  c.cutting_id = puc.cutting_id
	                      WHERE  pbd.packing_box_id = @dst_packing_box_id
	                  ) v
	           GROUP BY
	                  v.packing_box_id
	       ) vg
	WHERE  vg.cnt_fab > 1
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	INSERT INTO @update_data
		(
			pbd_id
		)
	SELECT	pbd.pbd_id
	FROM	@data_tab dt   
			LEFT JOIN	Products.ProdArticleNomenclatureTechSize pants   
			INNER JOIN	Manufactory.ProductUnicCode puc
				ON	puc.pants_id = pants.pants_id   
			INNER JOIN	Logistics.PackingBoxDetail pbd
				ON	pbd.product_unic_code = puc.product_unic_code
				AND	pbd.packing_box_id = @src_packing_box_id
				ON	pants.pants_id = dt.id
	
	IF NOT EXISTS (
	   	SELECT	1
	   	FROM	@update_data u
	   )
	BEGIN
	    RAISERROR('Нет товаров для перемещения', 16, 1)
	    RETURN
	END  
	
	SELECT	@error_text = CASE 
	      	                   WHEN es.employee_id IS NULL THEN 'Сотрудника с кодом ' + CAST(v.employee_id AS VARCHAR(10)) + ' не существует.'
	      	                   WHEN es.employee_id IS NOT NULL AND es.office_id IS NULL THEN 'У сотрудника ' + es.employee_name +
	      	                        ' не заполнен офис, в котором он работает'
	      	                   ELSE NULL
	      	              END,
			@place_id = os.buffer_zone_place_id
	FROM	(VALUES(@employee_id))v(employee_id)   
			LEFT JOIN	Settings.EmployeeSetting es
				ON	es.employee_id = v.employee_id   
			LEFT JOIN	Settings.OfficeSetting os
				ON	os.office_id = es.office_id
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END  
	
	BEGIN TRY
		BEGIN TRANSACTION
		
		UPDATE	pbd
		SET 	packing_box_id = @dst_packing_box_id,
				dt = @dt,
				employee_id = @employee_id
				OUTPUT	INSERTED.packing_box_id,
						INSERTED.product_unic_code
				INTO	@output_data (
						packing_box_id,
						product_unic_code
					)
		FROM	Logistics.PackingBoxDetail pbd
				INNER JOIN	@update_data d
					ON	d.pbd_id = pbd.pbd_id
		
		UPDATE	pb
		SET 	pb.close_dt = @dt,
				pb.close_employee_id = @employee_id
		FROM	Logistics.PackingBox pb
		WHERE	pb.packing_box_id IN (@src_packing_box_id, @dst_packing_box_id)
				AND	pb.close_dt IS NULL
		
		INSERT INTO History.PackingBoxDetail
			(
				packing_box_id,
				product_unic_code,
				dt,
				employee_id
			)
		SELECT	o.packing_box_id,
				o.product_unic_code,
				@dt,
				@employee_id
		FROM	@output_data o
		
		INSERT INTO Warehouse.PackingBoxOnPlace
			(
				packing_box_id,
				place_id,
				dt,
				employee_id
			)OUTPUT	INSERTED.packing_box_id,
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
			 	)
		SELECT	v.packing_box_id,
				@place_id,
				@dt,
				@employee_id
		FROM	(VALUES(@src_packing_box_id),
				(@dst_packing_box_id))v(packing_box_id)
		WHERE	NOT EXISTS (
		     		SELECT	1
		     		FROM	Warehouse.PackingBoxOnPlace pbop
		     		WHERE	pbop.packing_box_id = v.packing_box_id
		     	)
		
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
