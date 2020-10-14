CREATE PROCEDURE [Logistics].[PackingBox_ToBox]
	@src_packing_box_id INT = NULL,
	@product_uniq_data_martix_id INT = NULL,
	@dst_packing_box_id INT,
	@employee_id INT
AS
	SET NOCOUNT ON
	DECLARE @dt DATETIME2(0) = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	DECLARE @output_data TABLE (packing_box_id INT, product_unic_code INT)
	
	IF @src_packing_box_id IS NULL
	   AND @product_uniq_data_martix_id IS NULL
	BEGIN
	    RAISERROR('Не переданы данные, что переносить', 16, 1)
	    RETURN
	END
	
	IF @src_packing_box_id IS NULL
	BEGIN
	    SELECT	@src_packing_box_id = pbd.packing_box_id
	    FROM	Manufactory.ProductUniqDataMatrixProductUnic pudmpu   
	    		INNER JOIN	Logistics.PackingBoxDetail pbd
	    			ON	pbd.product_unic_code = pudmpu.product_unic_code
	    WHERE	pudmpu.product_uniq_data_martix_id = @product_uniq_data_martix_id
	END
	
	IF @src_packing_box_id IS NULL
	BEGIN
	    RAISERROR('Не определить коробку по уникальному коду продукта', 16, 1)
	    RETURN
	END
	
	IF @src_packing_box_id = @dst_packing_box_id
	BEGIN
	    RAISERROR('Коробка приемник и коробка источник должны различаться', 16, 1)
	    RETURN
	END
	
	SELECT	@error_text = CASE 
	      	                   WHEN pb.packing_box_id IS NULL THEN 'Коробка не валидная, используйте другой шк'
	      	                   WHEN pb.packing_box_id IS NOT NULL AND ISNULL(oa.cnt, 0) = 0 THEN 'В коробке нет товаров для перемещения'
	      	                   ELSE NULL
	      	              END
	FROM	(VALUES(@src_packing_box_id))v(packing_box_id)   
			LEFT JOIN	Logistics.PackingBox pb
				ON	pb.packing_box_id = v.packing_box_id   
			OUTER APPLY (
			      	SELECT	COUNT(1) cnt
			      	FROM	Logistics.PackingBoxDetail pbd
			      	WHERE	pbd.packing_box_id = pb.packing_box_id
			      ) oa 
	
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
	
	SET @error_text = 'После перемещения товаров, в коробке окажутся артикула с различающимися баркодами ' +(
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
    		    	 WHERE pbd.packing_box_id IN (@src_packing_box_id, @dst_packing_box_id)   	    	 				
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
		WHERE	pbd.packing_box_id = @src_packing_box_id
		
		IF @@ROWCOUNT != 0
		BEGIN
		    ROLLBACK TRANSACTION
		    RAISERROR('Что-то пошло не так, попробйте снова', 16, 1)
		END
		
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
		
		COMMIT TRANSACTION
		
		SELECT	b.brand_name,
				sj.subject_name,
				an.art_name,
				pa.sa        sa_imt,
				pan.sa       sa_nm,
				ts.ts_name,
				pa.sketch_id,
				k.kind_name,
				pan.whprice,
				pan.price_ru,
				COUNT(1)     cnt,
				puc.pants_id
		FROM	Manufactory.ProductUnicCode puc   
				INNER JOIN	Products.ProdArticleNomenclatureTechSize pants
					ON	pants.pants_id = puc.pants_id   
				INNER JOIN	Products.ProdArticleNomenclature pan
					ON	pan.pan_id = pants.pan_id   
				INNER JOIN	Products.ProdArticle pa
					ON	pa.pa_id = pan.pa_id   
				INNER JOIN	Products.Sketch s
					ON	s.sketch_id = pa.sketch_id   
				INNER JOIN	Products.Brand b
					ON	b.brand_id = pa.brand_id   
				INNER JOIN	Products.[Subject] sj
					ON	sj.subject_id = s.subject_id   
				INNER JOIN	Products.ArtName an
					ON	an.art_name_id = s.art_name_id   
				INNER JOIN	Products.Kind k
					ON	k.kind_id = s.kind_id   
				INNER JOIN	Products.TechSize ts
					ON	ts.ts_id = pants.ts_id   
				INNER JOIN	@output_data od
					ON	od.product_unic_code = puc.product_unic_code
		GROUP BY
			b.brand_name,
			sj.subject_name,
			an.art_name,
			pa.sa,
			pan.sa,
			ts.ts_name,
			pa.sketch_id,
			k.kind_name,
			pan.whprice,
			pan.price_ru,
			puc.pants_id
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
