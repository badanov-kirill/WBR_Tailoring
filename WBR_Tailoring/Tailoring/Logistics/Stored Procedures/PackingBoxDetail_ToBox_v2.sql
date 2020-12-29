﻿CREATE PROCEDURE [Logistics].[PackingBoxDetail_ToBox_v2]
	@src_packing_box_id INT,
	@dst_packing_box_id INT,
	@employee_id INT,
	@pants_id INT,
	@cnt SMALLINT
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
	      	                   WHEN pants.pants_id IS NULL THEN 'Идентификатора размера цветоварианта ' + CAST(dt.pants AS VARCHAR(20)) +
	      	                        ' не существует.'
	      	                   WHEN ISNULL(oa.cnt, 0) = 0 THEN 'Идентификатора размера цветоварианта ' + CAST(dt.pants AS VARCHAR(20)) +
	      	                        ' нет в коробке источнике.'
	      	                   WHEN ISNULL(oa.cnt, 0) != 0 AND ISNULL(oa.cnt, 0) < @cnt THEN 'Идентификатора размера цветоварианта ' + CAST(dt.pants AS VARCHAR(20)) 
	      	                        +
	      	                        ' не хватает в коробке источнике.'
	      	                   WHEN oabc.cnt_barcode > 1 THEN 'После перемещения в коробке окажется один артикул ' + pa.sa + pan.sa + ' с разными баркодами ' + oabc.barcode1 + ' и ' + oabc.barcode2
	      	                   ELSE NULL
	      	              END
	FROM	(VALUES(@pants_id))dt(pants)   
			LEFT JOIN	Products.ProdArticleNomenclatureTechSize pants
			INNER JOIN Products.ProdArticleNomenclature pan ON pan.pan_id = pants.pan_id
			INNER JOIN Products.ProdArticle pa ON pa.pa_id = pan.pa_id
				ON	pants.pants_id = dt.pants   
			OUTER APPLY (
			      	SELECT	COUNT(1) cnt
			      	FROM	Manufactory.ProductUnicCode puc   
			      			INNER JOIN	Logistics.PackingBoxDetail pbd
			      				ON	pbd.product_unic_code = puc.product_unic_code
			      	WHERE	puc.pants_id = pants.pants_id
			      			AND	pbd.packing_box_id = @src_packing_box_id
			      ) oa
			OUTER APPLY (
			      	SELECT	COUNT(DISTINCT pbd.barcode) cnt_barcode, MAX(pbd.barcode) barcode1, MIN(pbd.barcode) barcode2
			      	FROM	Manufactory.ProductUnicCode puc   
			      			INNER JOIN	Logistics.PackingBoxDetail pbd
			      				ON	pbd.product_unic_code = puc.product_unic_code
			      	WHERE	puc.pants_id = pants.pants_id
			      			AND	pbd.packing_box_id IN (@src_packing_box_id, @dst_packing_box_id)
			      ) oabc
	
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
	FROM	Products.ProdArticleNomenclatureTechSize pants   
			INNER JOIN	Manufactory.ProductUnicCode puc
				ON	puc.pants_id = pants.pants_id   
			INNER JOIN	Logistics.PackingBoxDetail pbd
				ON	pbd.product_unic_code = puc.product_unic_code
				AND	pbd.packing_box_id = @src_packing_box_id
	WHERE	pants.pants_id = @pants_id
	
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
		
		UPDATE	TOP(@cnt) pbd
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
		WHERE	pbd.packing_box_id = @src_packing_box_id
		
		IF @@ROWCOUNT != @cnt
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
