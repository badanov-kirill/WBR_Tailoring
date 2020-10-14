CREATE PROCEDURE [Material].[RawMaterialIncome_LoadInvoice]
	@doc_id INT,
	@rv_bigint BIGINT,
	@invoice_name VARCHAR(30),
	@invoice_dt DATE,
	@data_xml XML,
	@employee_id INT,
	@ttn_name VARCHAR(30) = NULL,
	@ttn_dt DATE = NULL
AS
	SET NOCOUNT ON 
	SET XACT_ABORT ON
	
	DECLARE @doc_type_id TINYINT = 1,
	        @dt DATETIME2(0) = GETDATE(),
	        @rmi_id INT,
	        @rmi_is_deleted BIT,
	        @error_text VARCHAR(MAX),
	        @rv ROWVERSION = CAST(@rv_bigint AS ROWVERSION)	,
	        @supplier_id INT
	
	DECLARE @goods_tab TABLE (
	        	item_name VARCHAR(200) NOT NULL,
	        	item_number SMALLINT NOT NULL,
	        	price DECIMAL(19, 8) NOT NULL,
	        	quantity DECIMAL(9, 3) NOT NULL,
	        	amount_with_nds DECIMAL(19, 8) NOT NULL,
	        	amount_nds DECIMAL(19, 8) NOT NULL,
	        	amount_without_nds DECIMAL(19, 8) NOT NULL,
	        	nds DECIMAL(19, 8) NOT NULL,
	        	okei_id INT NOT NULL,
	        	country_id INT NOT NULL,
	        	gtd_cod VARCHAR(30) NULL,
	        	rmii_id INT NULL,
	        	gtd_id INT NULL,
	        	item_code VARCHAR(200) NULL,
	        	rmiic_id INT NULL
	        )
	
	DECLARE @income_output TABLE (rv_bigint BIGINT)
	
	SELECT	@error_text = CASE 
	      	                   WHEN rm_inc.doc_id IS NULL THEN 'Поступления материалов с кодом ' + CAST(v.doc_id AS VARCHAR(10)) + ' не существует'
	      	                   WHEN rm_inc.rv != @rv THEN 'Документ уже кто-то поменял. Перечитайте данные и попробуйте записать снова.'
	      	                   WHEN rm_inc.is_deleted = 1 THEN 'Поступление материалов удалено'
	      	                   WHEN rmi.invoice_dt <> @invoice_dt AND rmi.is_deleted = 0 THEN 'Уже существует СФ с таким же номером, но с другой датой: ' + CAST(rmi.invoice_dt AS VARCHAR(12))
	      	              END,
			@rmi_id             = rmi.rmi_id,
			@rmi_is_deleted     = rmi.is_deleted,
			@supplier_id		= rm_inc.supplier_id
	FROM	(VALUES(@doc_id,
			@doc_type_id))v(doc_id,
			doc_type_id)   
			LEFT JOIN	Material.RawMaterialIncome rm_inc
				ON	rm_inc.doc_id = v.doc_id
				AND	rm_inc.doc_type_id = v.doc_type_id   
			LEFT JOIN	Material.RawMaterialInvoice rmi
				ON	rmi.doc_id = rm_inc.doc_id
				AND	rmi.doc_type_id = rm_inc.doc_type_id
				AND	rmi.invoice_name = @invoice_name
	
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
	   	WHERE	rmi.supplier_id = @supplier_id
	   			AND	rminv.is_deleted = 0
	   			AND	rmi.is_deleted = 0
	   			AND	rminv.invoice_name = @invoice_name
	   			AND	rminv.invoice_dt = @invoice_dt
	   			AND	rmi.doc_id != @doc_id
	   			AND rmi.doc_type_id = @doc_type_id
	)
	BEGIN
	    RAISERROR('Уже существует СФ с таким же номером и датой.', 16, 1)
	    RETURN
	END	
	
	INSERT @goods_tab
	  (
	    item_name,
	    item_number,
	    price,
	    quantity,
	    amount_with_nds,
	    amount_nds,
	    amount_without_nds,
	    nds,
	    okei_id,
	    country_id,
	    gtd_cod,
	    item_code
	  )
	SELECT	ml.value('@item_name', 'varchar(200)') item_name,
			ml.value('@item_number', 'SMALLINT') item_number,
			ml.value('@price', 'decimal(19,8)') price,
			ml.value('@quantity', 'decimal(9,3)') quantity,
			ml.value('@amount_with_nds', 'decimal(19,8)') amount_with_nds,
			ml.value('@amount_nds', 'decimal(19,8)') amount_nds,
			ml.value('@amount_without_nds', 'decimal(19,8)') amount_without_nds,
			ml.value('@nds', 'TINYINT')     nds,
			ml.value('@okei_id', 'INT')     okei_id,
			ml.value('@country_id', 'INT') country_id,
			ml.value('@gtd_cod', 'varchar(30)') gtd_cod,
			ml.value('@item_code', 'varchar(200)') item_code
	FROM	@data_xml.nodes('goods/good')x(ml)					 			
	
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
	    SELECT	@error_text = 'Не найдены следующие коды стран:' + CHAR(10)
	          	+ (
	          		SELECT	DISTINCT CAST(gt.country_id AS VARCHAR(10)) + CHAR(10)
	          		FROM	@goods_tab gt   
	          				LEFT JOIN	RefBook.Countries c
	          					ON	c.country_id = gt.country_id
	          		WHERE	c.country_id IS NULL
	          		FOR XML	PATH('')
	          	)
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('(%s) данные не загружены, проверьте файл.', 16, 1, @error_text)
	    RETURN
	END	
	
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
		
		INSERT INTO Material.RawMaterialInvoiceItemCode
			(
				item_code
			)
		SELECT	DISTINCT gt.item_code
		FROM	@goods_tab gt   
				LEFT JOIN	Material.RawMaterialInvoiceItemCode rmiic
					ON	rmiic.item_code = gt.item_code
		WHERE	rmiic.item_code IS NULL AND gt.item_code IS NOT NULL
		
		UPDATE	gt
		SET 	rmiic_id = rmiic.rmiic_id
		FROM	@goods_tab gt
				INNER JOIN	Material.RawMaterialInvoiceItemCode rmiic
					ON	rmiic.item_code = gt.item_code
		WHERE	rmiic.item_code IS NOT NULL AND gt.item_code IS NOT NULL
		
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
		END

		IF @rmi_id IS NULL
		BEGIN
		    INSERT Material.RawMaterialInvoice
		      (
		        doc_id,
		        doc_type_id,
		        invoice_name,
		        invoice_dt,
		        dt,
		        employee_id,
		        ttn_name, 
		        ttn_dt,
		        is_deleted
		      )
		    VALUES
		      (
		        @doc_id,
		        @doc_type_id,
		        @invoice_name,
		        @invoice_dt,
		        @dt,
		        @employee_id,
		        @ttn_name,
		        @ttn_dt,
		        0
		      ) 		    
		    
		    SET @rmi_id = SCOPE_IDENTITY()
		END
		ELSE	
		BEGIN
			UPDATE	Material.RawMaterialInvoice
			SET 	ttn_name       = @ttn_name,
					ttn_dt         = @ttn_dt,
					is_deleted     = 0,
					invoice_dt = @invoice_dt
			WHERE	rmi_id         = @rmi_id
					AND	(ISNULL(ttn_name, '') != ISNULL(@ttn_name, '') OR ISNULL(ttn_dt, @dt) != ISNULL(@ttn_dt, @dt) OR @rmi_is_deleted = 1 OR (invoice_dt != @invoice_dt)) 
		END;
				
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
		     			rmid.item_number,
		     			rmid.rmiic_id
		     	FROM	Material.RawMaterialInvoiceDetail rmid
		     	WHERE	rmid.rmi_id = @rmi_id
		     )			 		
		MERGE cte_target t
		USING (
		      	SELECT	@rmi_id        rmi_id,
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
		      			gt.gtd_id,
		      			gt.rmiic_id
		      	FROM	@goods_tab     gt
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
		     		t.gtd_id = s.gtd_id,
		     		t.rmiic_id = s.rmiic_id
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
		     		item_number,
		     		rmiic_id
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
		     		s.item_number,
		     		s.rmiic_id
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