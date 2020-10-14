CREATE PROCEDURE [Material].[RawMaterialIncome_LoadInvoiceForGamma]
	@doc_id INT,
	@data_xml XML,
	@rv_bigint BIGINT,
	@employee_id INT
AS
	SET NOCOUNT ON 
	SET XACT_ABORT ON
	
	DECLARE @doc_type_id TINYINT = 1,
	        @dt DATETIME2(0) = GETDATE(),
	        @error_text VARCHAR(MAX),
	        @rv ROWVERSION = CAST(@rv_bigint AS ROWVERSION),
	        @supplier_id INT
	
	DECLARE @invoce_output TABLE (rmi_id INT, invoice_name VARCHAR(30))        	
	
	DECLARE @goods_tab TABLE (
	        	invoice_name VARCHAR(30) NOT NULL,
	        	invoice_dt DATE NOT NULL,
	        	item_name VARCHAR(200) NOT NULL,
	        	item_number SMALLINT NOT NULL,
	        	price DECIMAL(19, 8) NOT NULL,
	        	quantity DECIMAL(9, 3) NOT NULL,
	        	amount_with_nds DECIMAL(19, 8) NOT NULL,
	        	amount_nds DECIMAL(19, 8) NOT NULL,
	        	amount_without_nds DECIMAL(19, 8) NOT NULL,
	        	nds DECIMAL(19, 8) NOT NULL,
	        	okei_id INT NOT NULL,
	        	country_name VARCHAR(100) NOT NULL,
	        	gtd_cod VARCHAR(30) NULL,
	        	rmii_id INT NULL,
	        	gtd_id INT NULL,
	        	country_id INT NULL,
	        	is_deleted BIT NULL
	        )
	
	DECLARE @income_output TABLE (rv_bigint BIGINT)
	
	SELECT	@error_text = CASE 
	      	                   WHEN rm_inc.doc_id IS NULL THEN 'Поступления материалов с кодом ' + CAST(v.doc_id AS VARCHAR(10)) + ' не существует'
	      	                   WHEN rm_inc.rv != @rv THEN 'Документ уже кто-то поменял. Перечитайте данные и попробуйте записать снова.'
	      	                   WHEN rm_inc.is_deleted = 1 THEN 'Поступление материалов удалено'
	      	              END,
	      	@supplier_id		= rm_inc.supplier_id
	FROM	(VALUES(@doc_id,
			@doc_type_id))v(doc_id,
			doc_type_id)   
			LEFT JOIN	Material.RawMaterialIncome rm_inc
				ON	rm_inc.doc_id = v.doc_id
				AND	rm_inc.doc_type_id = v.doc_type_id			
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('(%s) данные не загружены, проверьте файл.', 16, 1, @error_text)
	    RETURN
	END	
	
	INSERT @goods_tab
	  (
	    invoice_name,
	    invoice_dt,
	    item_name,
	    item_number,
	    price,
	    quantity,
	    amount_with_nds,
	    amount_nds,
	    amount_without_nds,
	    nds,
	    okei_id,
	    country_name,
	    gtd_cod,
	    country_id
	  )
	SELECT	ml.value('@invoice_name', 'varchar(30)') invoice_name,
			ml.value('@invoice_dt', 'DATE') invoice_dt,
			ml.value('@item_name', 'varchar(200)') item_name,
			ml.value('@item_number', 'SMALLINT') item_number,
			ml.value('@price', 'decimal(19,8)') price,
			ml.value('@quantity', 'decimal(9,3)') quantity,
			ml.value('@amount_with_nds', 'decimal(19,8)') amount_with_nds,
			ml.value('@amount_nds', 'decimal(19,8)') amount_nds,
			ml.value('@amount_without_nds', 'decimal(19,8)') amount_without_nds,
			ml.value('@nds', 'TINYINT')     nds,
			ml.value('@okei_id', 'INT')     okei_id,
			ml.value('@country_name', 'VARCHAR(100)') country_name,
			ml.value('@gtd_cod', 'varchar(30)') gtd_cod,
			c.country_id
	FROM	@data_xml.nodes('goods/good')x(ml)   
			LEFT JOIN	RefBook.Countries c
				ON	c.country_name = ml.value('@country_name',
			'VARCHAR(100)')					 			
	
	SELECT	@error_text = 'Не найдены следующие ставки НДС:' + CHAR(10)
	      	+ (
	      		SELECT	DISTINCT CAST(gt.nds AS VARCHAR(3)) + CHAR(10)
	      		FROM	@goods_tab gt   
	      				LEFT JOIN	RefBook.NDS n
	      					ON	n.nds = gt.nds
	      		WHERE	n.nds IS NULL
	      		FOR XML	PATH('')
	      	)
	
	IF @error_text IS NULL
	    SELECT	@error_text = 'Не найдены следующие коды OKEI:' + CHAR(10)
	          	+ (
	          		SELECT	DISTINCT CAST(gt.okei_id AS VARCHAR(10)) + CHAR(10)
	          		FROM	@goods_tab gt   
	          				LEFT JOIN	Qualifiers.OKEI o
	          					ON	o.okei_id = gt.okei_id
	          		WHERE	o.okei_id IS NULL
	          		FOR XML	PATH('')
	          	)     		
	
	IF @error_text IS NULL
	    SELECT	@error_text = 'Не найдены следующие страны:' + CHAR(10)
	          	+ (
	          		SELECT	DISTINCT CAST(gt.country_name AS VARCHAR(10)) + CHAR(10)
	          		FROM	@goods_tab gt
	          		WHERE	gt.country_id IS NULL
	          		FOR XML	PATH('')
	          	)
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('(%s) данные не загружены, проверьте файл.', 16, 1, @error_text)
	    RETURN
	END	
	
	IF EXISTS (
	   	SELECT	1
	   	FROM	Material.RawMaterialIncome rmi   
	   			INNER JOIN	Material.RawMaterialInvoice rminv
	   				ON	rminv.doc_id = rmi.doc_id
	   				AND	rminv.doc_type_id = rmi.doc_type_id
	   			INNER JOIN (
	   			           	SELECT	gt.invoice_name,
	   			           			gt.invoice_dt
	   			           	FROM	@goods_tab gt
	   			           	GROUP BY
	   			           		gt.invoice_name,
	   			           		gt.invoice_dt
	   			           ) v ON v.invoice_name = rminv.invoice_name AND v.invoice_dt = rminv.invoice_dt
	   	WHERE	rmi.supplier_id = @supplier_id
	   			AND	rminv.is_deleted = 0
	   			AND	rmi.is_deleted = 0
	   			AND	rmi.doc_id != @doc_id
	   			AND rmi.doc_type_id = @doc_type_id
	)
	BEGIN
	    RAISERROR('Уже существует СФ с таким же номером и датой.', 16, 1)
	    RETURN
	END	
	
	UPDATE	@goods_tab
	SET 	amount_nds             = ROUND((amount_with_nds / (CAST(nds AS DECIMAL(5, 2)) / 100 + 1) - amount_with_nds) * -1, 2),
			amount_without_nds     = amount_with_nds - ROUND((amount_with_nds / (CAST(nds AS DECIMAL(5, 2)) / 100 + 1) - amount_with_nds) * -1, 2)
	
	BEGIN TRY
		INSERT Material.RawMaterialInvoiceItem
		  (
		    item_name,
		    employee_id,
		    dt
		  )
		SELECT	DISTINCT gt.item_name,
				@employee_id        employee_id,
				@dt                 dt
		FROM	@goods_tab gt   
				LEFT JOIN	Material.RawMaterialInvoiceItem rmii
					ON	rmii.item_name = gt.item_name
		WHERE	rmii.rmii_id IS     NULL 
		
		UPDATE	gt
		SET 	gt.rmii_id = rmii.rmii_id
		FROM	@goods_tab gt
				INNER JOIN	Material.RawMaterialInvoiceItem rmii
					ON	rmii.item_name = gt.item_name					
		
		INSERT Material.GTD
		  (
		    gtd_cod
		  )
		SELECT	DISTINCT gt.gtd_cod
		FROM	@goods_tab gt   
				LEFT JOIN	Material.GTD g
					ON	g.gtd_cod = gt.gtd_cod
		WHERE	gt.gtd_cod IS NOT NULL
				AND	g.gtd_id IS NULL 
		
		UPDATE	gt
		SET 	gt.gtd_id = g.gtd_id
		FROM	@goods_tab gt
				INNER JOIN	Material.GTD g
					ON	g.gtd_cod = gt.gtd_cod
		WHERE	gt.gtd_cod IS NOT NULL 
		
		BEGIN TRANSACTION	
		
		UPDATE	Material.RawMaterialIncome
		SET 	employee_id = @employee_id,
				dt = @dt
				OUTPUT	CAST(INSERTED.rv AS BIGINT)
				INTO	@income_output (
						rv_bigint
					)
		WHERE	doc_id = @doc_id
				AND	doc_type_id = @doc_type_id
				AND	rv = @rv	
		
		IF @@ROWCOUNT = 0
		BEGIN
		    RAISERROR('Документ уже кто-то успел поменять. Перечитайте данные и попробуйте записать снова.', 16, 1)
		    RETURN
		END;
		
		MERGE Material.RawMaterialInvoice t
		USING (
		      	SELECT	DISTINCT 
		      	      	invoice_name,
		      			invoice_dt
		      	FROM	@goods_tab
		      )s
				ON t.doc_id = @doc_id
				AND t.doc_type_id = @doc_type_id
				AND t.invoice_name = s.invoice_name
		WHEN  MATCHED  THEN 
		     UPDATE	
		     SET 	t.is_deleted = 0,
		     		t.employee_id = @employee_id,
		     		t.dt = @dt
		WHEN NOT MATCHED  THEN 
		     INSERT
		     	(
		     		doc_id,
		     		doc_type_id,
		     		invoice_name,
		     		invoice_dt,
		     		dt,
		     		employee_id
		     	)
		     VALUES
		     	(
		     		@doc_id,
		     		@doc_type_id,
		     		s.invoice_name,
		     		s.invoice_dt,
		     		@dt,
		     		@employee_id
		     	)	           
		     OUTPUT	INSERTED.rmi_id,
		     		INSERTED.invoice_name
		     INTO	@invoce_output (
		     		rmi_id,
		     		invoice_name
		     	);		
		
		WITH cte_target AS (
		     	SELECT	rmid.rmi_id,
		     			rmid.rmii_id,
		     			rmid.price,
		     			rmid.quantity,
		     			rmid.amount_with_nds,
		     			rmid.amount_nds,
		     			rmid.amount_without_nds,
		     			rmid.nds,
		     			rmid.okei_id,
		     			rmid.country_id,
		     			rmid.gtd_id,
		     			rmid.item_number
		     	FROM	Material.RawMaterialInvoiceDetail rmid
		     	WHERE	EXISTS (
		     	     		SELECT	1
		     	     		FROM	@invoce_output inv_o
		     	     		WHERE	inv_o.rmi_id = rmid.rmi_id
		     	     	)
		     )		
		     MERGE cte_target t
		     USING (
		           	SELECT	inv_o.rmi_id,
		           			gt.invoice_dt,
		           			gt.item_name,
		           			gt.item_number,
		           			gt.price,
		           			gt.quantity,
		           			gt.amount_with_nds,
		           			gt.amount_nds,
		           			gt.amount_without_nds,
		           			gt.nds,
		           			gt.okei_id,
		           			gt.country_id,
		           			gt.gtd_cod,
		           			gt.rmii_id,
		           			gt.gtd_id
		           	FROM	@goods_tab gt   
		           			INNER JOIN	@invoce_output inv_o
		           				ON	inv_o.invoice_name = gt.invoice_name
		           ) s
		     		ON s.rmi_id = t.rmi_id
		     		AND s.item_number = t.item_number
		     WHEN  MATCHED  THEN 
		          UPDATE	
		          SET 	t.rmii_id = s.rmii_id,
		          		t.price = s.price,
		          		t.quantity = s.quantity,
		          		t.amount_with_nds = s.amount_with_nds,
		          		t.amount_nds = s.amount_nds,
		          		t.amount_without_nds = s.amount_without_nds,
		          		t.nds = s.nds,
		          		t.okei_id = s.okei_id,
		          		t.country_id = s.country_id,
		          		t.gtd_id = s.gtd_id
		     WHEN NOT MATCHED BY SOURCE THEN 
		          DELETE	
		     WHEN NOT MATCHED BY TARGET THEN 
		          INSERT
		          	(
		          		rmi_id,
		          		rmii_id,
		          		price,
		          		quantity,
		          		amount_with_nds,
		          		amount_nds,
		          		amount_without_nds,
		          		nds,
		          		okei_id,
		          		country_id,
		          		gtd_id,
		          		item_number
		          	)
		          VALUES
		          	(
		          		s.rmi_id,
		          		s.rmii_id,
		          		s.price,
		          		s.quantity,
		          		s.amount_with_nds,
		          		s.amount_nds,
		          		s.amount_without_nds,
		          		s.nds,
		          		s.okei_id,
		          		s.country_id,
		          		s.gtd_id,
		          		s.item_number
		          	); 
		
		COMMIT TRANSACTION
		
		SELECT	rv_bigint
		FROM	@income_output
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