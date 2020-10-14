CREATE PROCEDURE [Suppliers].[RawMaterialOrder_Set]
	@rmo_id INT = NULL,
	@supplier_id INT,
	@suppliercontract_id INT = NULL,
	@employee_id INT,
	@data_xml XML,
	@supply_dt DATETIME2(0),
	@comment VARCHAR(200) = NULL,
	@is_deleted BIT = 0
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @dt DATETIME2(0) = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	DECLARE @data_tab TABLE (rmod_id INT, rmt_id INT, color_id INT, okei_id INT, frame_width SMALLINT, comment VARCHAR(300), qty DECIMAL(9, 3), price_cur DECIMAL(9, 2), currency_id INT)
	DECLARE @raw_material_order_output TABLE (rmo_id INT)
	DECLARE @rmod_status_ordered TINYINT = 1 -- заказан у поставщика 
	DECLARE @rmod_status_deleted TINYINT = 2 -- удален
	
	SELECT	@error_text = CASE 
	      	                   WHEN s.supplier_id IS NULL THEN 'Поставщика с кодом ' + CAST(v.supplier_id AS VARCHAR(10)) + ' не существует.'
	      	                   ELSE NULL
	      	              END,
			@suppliercontract_id = ISNULL(@suppliercontract_id, oa.suppliercontract_id)
	FROM	(VALUES(@supplier_id))v(supplier_id)   
			LEFT JOIN	Suppliers.Supplier s
				ON	s.supplier_id = v.supplier_id   
			OUTER APPLY (
			      	SELECT	TOP(1) sc.suppliercontract_id
			      	FROM	Suppliers.SupplierContract sc
			      	WHERE	sc.supplier_id = s.supplier_id
			      	ORDER BY
			      		CASE 
			      		     WHEN sc.is_default = 1 THEN 0
			      		     ELSE 1
			      		END,
			      		sc.suppliercontract_id DESC
			      ) oa
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END		     
	
	IF @suppliercontract_id IS NULL
	BEGIN
	    RAISERROR('У поставщика нет договора.', 16, 1)
	    RETURN
	END
	
	IF NOT EXISTS (
	   	SELECT	1
	   	FROM	Suppliers.SupplierContract sc
	   	WHERE	sc.suppliercontract_id = @suppliercontract_id
	   			AND	sc.supplier_id = @supplier_id
	   )
	BEGIN
	    RAISERROR('Не корректный договор поставщика.', 16, 1)
	    RETURN
	END
	
	IF @rmo_id IS NOT NULL
	BEGIN
	    SELECT	@error_text = CASE 
	          	                   WHEN rmo.rmo_id IS NULL THEN 'Поставки с номером ' + CAST(v.rmo_id AS VARCHAR(10)) + ' не существует.'
	          	                   WHEN rmo.supplier_id != @supplier_id THEN 'Нельзя менять поставщика'
	          	                   ELSE NULL
	          	              END
	    FROM	(VALUES(@rmo_id))v(rmo_id)   
	    		LEFT JOIN	Suppliers.RawMaterialOrder rmo
	    			ON	rmo.rmo_id = v.rmo_id  
	    
	    IF @error_text IS NOT NULL
	    BEGIN
	        RAISERROR('%s', 16, 1, @error_text)
	        RETURN
	    END
	END
	
	INSERT INTO @data_tab
	  (
	    rmod_id,
	    rmt_id,
	    color_id,
	    okei_id,
	    frame_width,
	    comment,
	    qty,
	    price_cur,
	    currency_id
	  )
	SELECT	ml.value('@rmod[1]', 'int'),
			ml.value('@rmt[1]', 'int'),
			ml.value('@color[1]', 'int'),
			ml.value('@okei[1]', 'int'),
			ml.value('@fw[1]', 'smallint'),
			ml.value('@com[1]', 'varchar(300)'),
			ml.value('@qty[1]', 'decimal(9,3)'),
			ml.value('@pr[1]', 'decimal(9,2)'),
			ml.value('@cur[1]', 'int')
	FROM	@data_xml.nodes('root/det')x(ml)
	
	SELECT	@error_text = CASE 
	      	                   WHEN dt.rmod_id IS NOT NULL AND rmod.rmod_id IS NULL THEN 'Строки детали заказа с кодом ' + CAST(dt.rmod_id AS VARCHAR(10)) +
	      	                        ' не существует.'
	      	                   WHEN rmod.rmod_id IS NOT NULL AND rmod.rmo_id != @rmo_id THEN 'Строки детали заказа с кодом ' + CAST(dt.rmod_id AS VARCHAR(10)) +
	      	                        ' относится к другому заказу.'
	      	                   WHEN dt.rmod_id IS NOT NULL AND dt.rmt_id != rmod.rmt_id THEN 'Нельзя менять тип материала существующей строки'
	      	                   WHEN dt.rmod_id IS NOT NULL AND dt.color_id != rmod.color_id THEN 'Нельзя менять цвет существующей строки'
	      	                   WHEN rmt.rmt_id IS NULL THEN 'Типа материала с кодом ' + CAST(dt.rmt_id AS VARCHAR(10)) + ' не существует.'
	      	                   WHEN cc.color_id IS NULL THEN 'Цвета с кодом ' + CAST(dt.color_id AS VARCHAR(10)) + ' не существует.'
	      	                   WHEN o.okei_id IS NULL THEN 'Еденицы измерения с кодом ' + CAST(dt.okei_id AS VARCHAR(10)) + ' не существует.'
	      	                   WHEN c.currency_id IS NULL THEN 'Валюты с кодом ' + CAST(dt.currency_id AS VARCHAR(10)) + ' не существует.'
	      	                   WHEN ISNULL(dt.qty, 0) <= 0 THEN 'Не корректно указано количество.'
	      	                   WHEN ISNULL(dt.price_cur, 0) <= 0 THEN 'Не корректно указана цена.'
	      	                   ELSE NULL
	      	              END
	FROM	@data_tab dt   
			LEFT JOIN	Suppliers.RawMaterialOrderDetail rmod
				ON	rmod.rmod_id = dt.rmod_id   
			LEFT JOIN	Material.RawMaterialType rmt
				ON	rmt.rmt_id = dt.rmt_id   
			LEFT JOIN	Material.ClothColor cc
				ON	cc.color_id = dt.color_id   
			LEFT JOIN	Qualifiers.OKEI o
				ON	o.okei_id = dt.okei_id   
			LEFT JOIN	RefBook.Currency c
				ON	c.currency_id = dt.currency_id
	WHERE	(dt.rmod_id IS NOT NULL AND rmod.rmod_id IS NULL)
			OR	(rmod.rmod_id IS NOT NULL AND rmod.rmo_id != @rmo_id)
			OR	rmt.rmt_id IS NULL
			OR	cc.color_id IS NULL
			OR	o.okei_id IS NULL
			OR	c.currency_id IS NULL
			OR	ISNULL(dt.qty, 0) <= 0
			OR	ISNULL(dt.price_cur, 0) <= 0
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END		    
	
	BEGIN TRY
		BEGIN TRANSACTION
		
		IF @rmo_id IS NULL
		BEGIN
		    INSERT INTO Suppliers.RawMaterialOrder
		      (
		        create_dt,
		        create_employee_id,
		        supplier_id,
		        suppliercontract_id,
		        supply_dt,
		        is_deleted,
		        comment,
		        employee_id,
		        dt
		      )OUTPUT	INSERTED.rmo_id
		       INTO	@raw_material_order_output (
		       		rmo_id
		       	)
		    VALUES
		      (
		        @dt,
		        @employee_id,
		        @supplier_id,
		        @suppliercontract_id,
		        @supply_dt,
		        0,
		        @comment,
		        @employee_id,
		        @dt
		      )
		    
		    SELECT	@rmo_id = rmoo.rmo_id
		    FROM	@raw_material_order_output rmoo
		END
		ELSE
		BEGIN
		    UPDATE	Suppliers.RawMaterialOrder
		    SET 	suppliercontract_id     = @suppliercontract_id,
		    		supply_dt               = @supply_dt,
		    		is_deleted              = @is_deleted,
		    		comment                 = @comment,
		    		employee_id             = @employee_id,
		    		dt                      = @dt
		    		OUTPUT	INSERTED.rmo_id
		    		INTO	@raw_material_order_output (
		    				rmo_id
		    			)
		    WHERE	rmo_id                  = @rmo_id
		END 
		
		;
		WITH cte_Target AS (
			SELECT	rmod.rmod_id,
					rmod.rmo_id,
					rmod.rmt_id,
					rmod.color_id,
					rmod.okei_id,
					rmod.frame_width,
					rmod.comment,
					rmod.qty,
					rmod.price_cur,
					rmod.currency_id,
					rmod.rmods_id,
					rmod.employee_id,
					rmod.dt
			FROM	Suppliers.RawMaterialOrderDetail rmod
			WHERE	rmod.rmo_id = @rmo_id
		)
		MERGE cte_Target t
		USING @data_tab s
				ON s.rmod_id = t.rmod_id
		WHEN MATCHED THEN 
		     UPDATE	
		     SET 	okei_id         = s.okei_id,
		     		frame_width     = s.frame_width,
		     		comment         = s.comment,
		     		qty             = s.qty,
		     		price_cur       = s.price_cur,
		     		currency_id     = s.currency_id,
		     		employee_id     = @employee_id,
		     		dt              = @dt
		WHEN NOT MATCHED BY TARGET THEN 
		     INSERT
		     	(
		     		rmo_id,
		     		rmt_id,
		     		color_id,
		     		okei_id,
		     		frame_width,
		     		comment,
		     		qty,
		     		price_cur,
		     		currency_id,
		     		rmods_id,
		     		employee_id,
		     		dt
		     	)
		     VALUES
		     	(
		     		@rmo_id,
		     		s.rmt_id,
		     		s.color_id,
		     		s.okei_id,
		     		s.frame_width,
		     		s.comment,
		     		s.qty,
		     		s.price_cur,
		     		s.currency_id,
		     		@rmod_status_ordered,
		     		@employee_id,
		     		@dt
		     	)
		WHEN NOT MATCHED BY SOURCE THEN 
		     UPDATE	
		     SET 	rmods_id        = @rmod_status_deleted,
		     		employee_id     = @employee_id,
		     		dt              = @dt; 
		
		COMMIT TRANSACTION
		
		SELECT	rmoo.rmo_id
		FROM	@raw_material_order_output rmoo
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