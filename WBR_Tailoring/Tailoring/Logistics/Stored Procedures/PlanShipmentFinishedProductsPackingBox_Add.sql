CREATE PROCEDURE [Logistics].[PlanShipmentFinishedProductsPackingBox_Add]
	@tab dbo.List READONLY,
	@sfp_id INT,
	@employee_id INT
AS
	SET NOCOUNT ON
	DECLARE @dt DATETIME2(0) = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	
	SELECT	@error_text = CASE 
	      	                   WHEN pb.packing_box_id IS NULL THEN 'Коробки с кодом ' + CAST(dt.id AS VARCHAR(10)) + ' не существует.'
	      	                   WHEN pb.packing_box_id IS NOT NULL AND pb.close_dt IS NULL THEN 'Коробки с кодом ' + CAST(dt.id AS VARCHAR(10)) + ' не закрыта.'
	      	                   WHEN psfppb.psfpd_id IS NOT NULL THEN 'Коробки с кодом ' + CAST(dt.id AS VARCHAR(10)) + ' уже запланирована в отгрузку № ' + CAST(psfppb.sfp_id AS VARCHAR(10))
	      	                   WHEN sfppb.sfpd_id IS NOT NULL THEN 'Коробки с кодом ' + CAST(dt.id AS VARCHAR(10)) + ' уже отсканирована в отгрузку № ' + CAST(sfppb.sfp_id AS VARCHAR(10))
	      	                   ELSE NULL
	      	              END
	FROM	@tab dt   
			LEFT JOIN	Logistics.PackingBox pb
				ON	dt.id = pb.packing_box_id   
			LEFT JOIN	Logistics.PlanShipmentFinishedProductsPackingBox psfppb
				ON	psfppb.packing_box_id = pb.packing_box_id   
			LEFT JOIN	Logistics.ShipmentFinishedProductsPackingBox sfppb
				ON	sfppb.packing_box_id = pb.packing_box_id
	WHERE pb.packing_box_id IS NULL
	OR pb.close_dt IS NULL
	OR psfppb.psfpd_id IS NOT NULL
	OR sfppb.sfpd_id IS NOT NULL
	
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('(%s).', 16, 1, @error_text)
	    RETURN
	END
	
	SELECT	@error_text = CASE 
	      	                   WHEN s.sfp_id IS NULL THEN 'Отгрузки с номером ' + CAST(v.sfp_id AS VARCHAR(10)) + ' не существует.'
	      	                   WHEN s.complite_dt IS NOT NULL THEN 'Отгрузка № ' + CAST(s.sfp_id AS VARCHAR(10)) + ' уже отправлена'
	      	                   ELSE NULL
	      	              END
	FROM	(VALUES(@sfp_id))v(sfp_id)   
			LEFT JOIN	Logistics.ShipmentFinishedProducts s
				ON	s.sfp_id = v.sfp_id   
	
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END	
	
	SET @error_text = 'После добавления коробок, в отгрузке окажутся артикула с различающимися баркодами ' +(
    		SELECT	CHAR(10) + 'Арт: ' + v.sa + v.sanm + ' ' + v.ts_name + ', баркоды: ' + v.barcode1 + ' и ' + v.barcode2
    		FROM	(SELECT	TOP(3) pa.sa         sa,
    	    	 			pan.sa               sanm,
    	    	 			ts.ts_name,
    	    	 			MAX(pbd.barcode)     barcode1,
    	    	 			MIN(pbd.barcode)     barcode2
    	    		 FROM	Logistics.PackingBoxDetail pbd 
    	    				INNER JOIN	Manufactory.ProductUnicCode puc
    	    					ON puc.product_unic_code = pbd.product_unic_code
    	    	 			INNER JOIN	Products.ProdArticleNomenclatureTechSize pants   
    	    	 				ON pants.pants_id = puc.pants_id
    	    	 			INNER JOIN	Products.TechSize ts
    	    	 				ON	ts.ts_id = pants.ts_id   
    	    	 			INNER JOIN	Products.ProdArticleNomenclature pan
    	    	 				ON	pan.pan_id = pants.pan_id   
    	    	 			INNER JOIN	Products.ProdArticle pa
    	    	 				ON	pa.pa_id = pan.pa_id      	    	 				
    		    	 WHERE EXISTS (
    		    	              	SELECT	1
    		    	              	FROM	@tab dt
    		    	              	WHERE	dt.id = pbd.packing_box_id
    		    	              ) 
    		    		   OR EXISTS (
    		    	           			SELECT	1
    		    	           			FROM	Logistics.PlanShipmentFinishedProductsPackingBox sfpb
    		    	           			WHERE	sfpb.sfp_id = @sfp_id
    		    	           					AND	sfpb.packing_box_id = pbd.packing_box_id
    		    					   ) 	    	 				
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
	
	DECLARE @cnt_fab INT = 0
	SELECT @cnt_fab = COUNT(DISTINCT f.fabricator_id)
	       FROM   Logistics.PackingBoxDetail pbd
	              INNER JOIN Manufactory.ProductUnicCode puc
	                   ON  puc.product_unic_code = pbd.product_unic_code
	              INNER JOIN Manufactory.Cutting c
	                   ON  c.cutting_id = puc.cutting_id
	              INNER JOIN Planing.SketchPlanColorVariantTS AS spcvt
	                   ON  spcvt.spcvts_id = c.spcvts_id
	              INNER JOIN Planing.SketchPlanColorVariant AS spcv
	                   ON  spcv.spcv_id = spcvt.spcv_id
	              INNER JOIN Settings.Fabricators AS f
	                   ON  f.fabricator_id = spcv.sew_fabricator_id
	       WHERE  EXISTS (
	                  SELECT 1
	                  FROM   @tab dt
	                  WHERE  dt.id = pbd.packing_box_id
	              )
	              OR  EXISTS (
	                      SELECT 1
	                      FROM   Logistics.PlanShipmentFinishedProductsPackingBox sfpb
	                      WHERE  sfpb.sfp_id = @sfp_id
	                             AND sfpb.packing_box_id = pbd.packing_box_id);
	
	IF @cnt_fab > 1
	begin                  	
	SELECT @error_text = 'После добавления коробок, в отгрузке окажутся коробки от разных производителей ' + CHAR(10) +(
	           SELECT string_agg(v2.error_text, CHAR(10))
	           FROM   (
	                      SELECT + 'Производитель: ' + v.fabricator_name + ', коробки: ' + string_agg(v.packing_box_id, '; ') 
	                             error_text
	                      FROM   (
	                                 SELECT DISTINCT f.fabricator_name,
	                                        CAST(pbd.packing_box_id AS VARCHAR(MAX)) packing_box_id
	                                 FROM   Logistics.PackingBoxDetail pbd
	                                        INNER JOIN Manufactory.ProductUnicCode puc
	                                             ON  puc.product_unic_code = pbd.product_unic_code
	                                        INNER JOIN Manufactory.Cutting c
	                                             ON  c.cutting_id = puc.cutting_id
	                                        INNER JOIN Planing.SketchPlanColorVariantTS AS spcvt
	                                             ON  spcvt.spcvts_id = c.spcvts_id
	                                        INNER JOIN Planing.SketchPlanColorVariant AS spcv
	                                             ON  spcv.spcv_id = spcvt.spcv_id
	                                        INNER JOIN Settings.Fabricators AS f
	                                             ON  f.fabricator_id = spcv.sew_fabricator_id
	                                 WHERE  EXISTS (
	                                            SELECT 1
	                                            FROM   @tab dt
	                                            WHERE  dt.id = pbd.packing_box_id
	                                        )
	                                        OR  EXISTS (
	                                                SELECT 1
	                                                FROM   Logistics.PlanShipmentFinishedProductsPackingBox sfpb
	                                                WHERE  sfpb.sfp_id = @sfp_id
	                                                       AND sfpb.packing_box_id = pbd.packing_box_id
	                                            )
	                             )v
	                      GROUP BY
	                             v.fabricator_name
	                  ) v2
	)
	end

	IF @error_text IS NOT NULL
	BEGIN
		RAISERROR('%s', 16, 1, @error_text)
		RETURN
	END
	
	BEGIN TRY
		BEGIN TRANSACTION 	
		
		INSERT INTO Logistics.PlanShipmentFinishedProductsPackingBox
			(
				sfp_id,
				packing_box_id,
				dt,
				employee_id
			)
		SELECT	@sfp_id,
				dt.id,
				@dt,
				@employee_id
		FROM	@tab dt
		
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
GO