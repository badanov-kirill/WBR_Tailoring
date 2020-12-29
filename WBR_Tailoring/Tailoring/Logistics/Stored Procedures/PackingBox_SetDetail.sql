CREATE PROCEDURE [Logistics].[PackingBox_SetDetail]
	@product_uniq_data_martix_id INT,
	@dst_packing_box_id INT,
	@employee_id INT
AS
	SET NOCOUNT ON
	DECLARE @dt DATETIME2(0) = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	DECLARE @product_unic_code INT
	DECLARE @barcode VARCHAR(13)
	DECLARE @place_id INT
	DECLARE @proc_id INT
	EXECUTE @proc_id = History.ProcId_GetByName @procid = @@PROCID	
	
	SELECT	@error_text = CASE 
	      	                   WHEN pudmpu.product_uniq_data_martix_id IS NULL THEN 
	      	                        'Уникальный код пакета не связан с изделием. Отложите товар и обратитесь к руководителю'
	      	                   WHEN pbd.pbd_id IS NULL AND e.pants_id IS NULL THEN 
	      	                   		'Не удалось определить баркод изделия, обратитесь к руководителю'
	      	                   ELSE NULL
	      	              END,
	      	@barcode = e.ean,
			@product_unic_code = pudmpu.product_unic_code
	FROM	(VALUES(@product_uniq_data_martix_id))v(product_uniq_data_martix_id)   
			LEFT JOIN	Manufactory.ProductUniqDataMatrixProductUnic pudmpu
				ON	pudmpu.product_uniq_data_martix_id = v.product_uniq_data_martix_id
			LEFT JOIN Logistics.PackingBoxDetail pbd
				ON pbd.product_unic_code = pudmpu.product_unic_code
			LEFT JOIN Manufactory.ProductUnicCode puc
				ON puc.product_unic_code = pudmpu.product_unic_code
			LEFT JOIN Manufactory.EANCode e
				ON e.pants_id = puc.pants_id
	
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
		
		;
		MERGE Logistics.PackingBoxDetail t
		USING (
		      	SELECT	@product_unic_code product_unic_code,
		      			@dst_packing_box_id dst_packing_box_id
		      ) s
				ON t.product_unic_code = s.product_unic_code
		WHEN MATCHED THEN 
		     UPDATE	
		     SET 	packing_box_id     = s.dst_packing_box_id,
		     		dt                 = @dt,
		     		employee_id        = @employee_id
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
		     		s.dst_packing_box_id,
		     		s.product_unic_code,
		     		@dt,
		     		@employee_id,
		     		@barcode
		     	);
		
		
		UPDATE	pb
		SET 	pb.close_dt = @dt,
				pb.close_employee_id = @employee_id
		FROM	Logistics.PackingBox pb
		WHERE	pb.packing_box_id = @dst_packing_box_id
				AND	pb.close_dt IS NULL
		
		INSERT INTO History.PackingBoxDetail
			(
				packing_box_id,
				product_unic_code,
				dt,
				employee_id
			)
		SELECT	@dst_packing_box_id,
				@product_unic_code,
				@dt,
				@employee_id
		
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
		FROM	(VALUES(@dst_packing_box_id))v(packing_box_id)
		WHERE	NOT EXISTS (
		     		SELECT	1
		     		FROM	Warehouse.PackingBoxOnPlace pbop
		     		WHERE	pbop.packing_box_id = v.packing_box_id
		     	)
		
		COMMIT TRANSACTION
		
		SELECT	b.brand_name,
				sj.subject_name,
				an.art_name,
				pa.sa      sa_imt,
				pan.sa     sa_nm,
				ts.ts_name,
				pa.sketch_id,
				k.kind_name,
				pan.whprice,
				pan.price_ru,
				1          cnt,
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
		WHERE	puc.product_unic_code = @product_unic_code
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