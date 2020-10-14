CREATE PROCEDURE [Material].[RawMaterialIncome_LoadInvoiceByUPD]
	@doc_id INT,
	@employee_id INT,
	@doc_upd dbo.List READONLY
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @doc_type_id TINYINT = 1,
	        @dt DATETIME2(0) = GETDATE(),
	        @error_text VARCHAR(MAX),
	        @supplier_id INT,
	        @suppliercontract_id INT,
	        @old_suppliercontract_id INT,
	        @count INT
	
	
	DECLARE @invoce_output TABLE (rmi_id INT, invoice_name VARCHAR(30), invoice_dt DATE)  
	
	DECLARE @goods_tab TABLE (
	        	esf_id INT NOT NULL,
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
	        	okei_code VARCHAR(10) NULL,
	        	okei_id INT NULL,
	        	rmii_id INT NULL,
	        	gtd_id INT NULL,
	        	edo_country_id INT NULL,
	        	country_id INT NULL,
	        	is_deleted BIT NULL,
	        	item_code VARCHAR(200) NULL,
	        	rmiic_id INT NULL
	        )
	
	SELECT	@error_text = CASE 
	      	                   WHEN rm_inc.doc_id IS NULL THEN 'Поступления материалов с кодом ' + CAST(v.doc_id AS VARCHAR(10)) + ' не существует'
	      	                   WHEN rm_inc.is_deleted = 1 THEN 'Поступление материалов удалено'
	      	                   WHEN rm_inc.rmis_id > 5 THEN 'Поступление закрыто'
	      	              END,
			@supplier_id             = rm_inc.supplier_id
	FROM	(VALUES(@doc_id,
			@doc_type_id))v(doc_id,
			doc_type_id)   
			LEFT JOIN	Material.RawMaterialIncome rm_inc
				ON	rm_inc.doc_id = v.doc_id
				AND	rm_inc.doc_type_id = v.doc_type_id			
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s.', 16, 1, @error_text)
	    RETURN
	END	
	
	SELECT	@error_text = CASE 
	      	                   WHEN COUNT(1) = 0 THEN 'Не передано ни одного УПД'
	      	                   WHEN COUNT(d.id) != COUNT(dud.dud_id) THEN 'Передан некорректный список УПД'
	      	                   WHEN COUNT(DISTINCT dud.suppliercontract_id) > 1 THEN 'Выбранные УПД должны быть с одним договором'
	      	                   WHEN COUNT(DISTINCT dud.suppliercontract_id) = 1 AND MAX(ISNULL(sc.suppliercontract_id, 0)) = 0 THEN 
	      	                        'Договор УПД отсутствует в базе производства'
	      	                   WHEN MAX(ISNULL(dum.esf_id, 0)) != 0 THEN 'УПД с кодом ' + CAST(MAX(ISNULL(dum.esf_id, 0)) AS VARCHAR(10)) +
	      	                        ' уже загружено в другое поступление.'
	      	                   WHEN COUNT(dud.esf_id) != COUNT(DISTINCT dud.esf_id) THEN 'Не уникальный набор документов'
	      	                   WHEN COUNT(dud.edo_doc_num) != COUNT(DISTINCT LEFT(dud.edo_doc_num, 30)) THEN 'Не уникальные номера документов'
	      	                   WHEN MAX(ISNULL(dud.dt_proc, '')) != '' THEN 'Выбранные УПД содержат уже обработанные строки.'
	      	                   ELSE NULL
	      	              END,
			@count = COUNT(1),
			@suppliercontract_id = MAX(ISNULL(sc.suppliercontract_id, 0))
	FROM	@doc_upd d   
			LEFT JOIN	Synchro.DownloadUPD_Doc dud
				ON	dud.dud_id = d.id   
			LEFT JOIN	Suppliers.SupplierContract sc
				ON	sc.suppliercontract_erp_id = dud.suppliercontract_id   
			LEFT JOIN	Synchro.DownloadUPD_Mapping dum   
			INNER JOIN	Material.RawMaterialInvoice rmi
				ON	rmi.rmi_id = dum.rmi_id
				AND	rmi.doc_id != @doc_id
				ON	dum.esf_id = dud.esf_id  
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END	
	
	IF EXISTS (
	   	SELECT	1
	   	FROM	Material.RawMaterialIncome rmi   
	   			INNER JOIN	Material.RawMaterialInvoice rminv
	   				ON	rminv.doc_id = rmi.doc_id
	   				AND	rminv.doc_type_id = rmi.doc_type_id   
	   			INNER JOIN	(SELECT	LEFT(dud.edo_doc_num, 30) invoice_name,
	   			    	     	 		dud.edo_doc_dt invoice_dt
	   			    	     	 FROM	@doc_upd d   
	   			    	     	 		INNER JOIN	Synchro.DownloadUPD_Doc dud
	   			    	     	 			ON	dud.dud_id = d.id)v
	   				ON	v.invoice_name = rminv.invoice_name
	   				AND	v.invoice_dt = rminv.invoice_dt
	   	WHERE	rmi.supplier_id = @supplier_id
	   			AND	rminv.is_deleted = 0
	   			AND	rmi.is_deleted = 0
	   			AND	rmi.doc_id != @doc_id
	   			AND	rmi.doc_type_id = @doc_type_id
	   )
	BEGIN
	    RAISERROR('Уже существует подгруженная СФ с номером и датой, как в выбранных УПД.', 16, 1)
	    RETURN
	END
	
	INSERT INTO @goods_tab
		(
			esf_id,
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
			okei_code,
			okei_id,
			gtd_id,
			edo_country_id,
			country_id,
			is_deleted,
			item_code
		)
	SELECT	dudd.esf_id,
			dud.edo_doc_num                 invoice_name,
			dud.edo_doc_dt                  invoice_dt,
			dui.item_name                   item_name,
			dudd.edo_pos_id                 item_number,
			dudd.edo_price                  price,
			dudd.edo_quantity               quantity,
			dudd.edo_amount_with_nds        amount_with_nds,
			dudd.edo_amount_nds             amount_nds,
			dudd.edo_amount_without_nds     amount_without_nds,
			dudd.edo_vat                    nds,
			dudd.edo_okei_code              okei_code,
			o.okei_id                       okei_id,
			dudd.gtd_id                     gtd_id,
			dudd.edo_country_id,
			c.country_id                    country_id,
			0                               is_deleted,
			duic.item_name					item_code
	FROM	@doc_upd d   
			INNER JOIN	Synchro.DownloadUPD_Doc dud
				ON	dud.dud_id = d.id   
			INNER JOIN	Synchro.DownloadUPD_DocDetail dudd
				ON	dudd.dud_id = dud.dud_id   
			LEFT JOIN	Synchro.DownloadUPD_Item dui
				ON	dui.dui_id = dudd.dui_id_item_name  
			LEFT JOIN	Synchro.DownloadUPD_Item duic
				ON duic.dui_id = dudd.dui_id_item_code 
			LEFT JOIN	Qualifiers.OKEI o
				ON	o.okei_id = TRY_CONVERT(INT,
			dudd.edo_okei_code)   
			LEFT JOIN	RefBook.Countries c
				ON	dudd.edo_country_id = c.country_id
	
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
	          		SELECT	DISTINCT gt.okei_code + CHAR(10)
	          		FROM	@goods_tab gt
	          		WHERE	gt.okei_id IS NULL
	          		FOR XML	PATH('')
	          	)     		
	
	IF @error_text IS NULL
	    SELECT	@error_text = 'Не найдены следующие коды стран:' + CHAR(10)
	          	+ (
	          		SELECT	DISTINCT CAST(gt.edo_country_id AS VARCHAR(10)) + CHAR(10)
	          		FROM	@goods_tab gt
	          		WHERE	gt.country_id IS NULL
	          				AND	gt.edo_country_id IS NOT NULL
	          		FOR XML	PATH('')
	          	)
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END	
	
	IF EXISTS (
	   	SELECT	1
	   	FROM	@goods_tab gt
	   	WHERE	gt.item_name IS NULL
	   )
	BEGIN
	    RAISERROR('Есть позиция без наименования, загружать нельзя.', 16, 1)
	    RETURN
	END		
	
	IF EXISTS (
	   	SELECT	1
	   	FROM	@goods_tab gt
	   	WHERE	gt.item_number IS NULL
	   )
	BEGIN
	    RAISERROR('Есть позиция без номера, загружать нельзя.', 16, 1)
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
		WHERE	gt.item_code IS NOT NULL
		
		BEGIN TRANSACTION
		
		IF @old_suppliercontract_id != @suppliercontract_id
		BEGIN
		    UPDATE	Material.RawMaterialIncome
		    SET 	suppliercontract_id = @suppliercontract_id
		    WHERE	doc_id = @doc_id
		    		AND	doc_type_id = @doc_type_id
		    
		    UPDATE	Material.RawMaterialIncomeDetail
		    SET 	suppliercontract_id = @suppliercontract_id
		    WHERE	doc_id = @doc_id
		    		AND	doc_type_id = @doc_type_id
		    
		    UPDATE	Warehouse.SHKRawMaterialActualInfo
		    SET 	suppliercontract_id = @suppliercontract_id
		    WHERE	doc_id = @doc_id
		    		AND	doc_type_id = @doc_type_id
		    
		    UPDATE	Warehouse.SHKRawMaterialInfo
		    SET 	suppliercontract_id     = @suppliercontract_id
		    WHERE	doc_id                  = @doc_id
		    		AND	doc_type_id         = @doc_type_id
		END
		
		UPDATE	dud
		SET 	dud.dt_proc = @dt
		FROM	Synchro.DownloadUPD_Doc dud
				INNER JOIN	@doc_upd d
					ON	dud.dud_id = d.id
		WHERE	dud.dt_proc IS NULL
		
		IF @@ROWCOUNT != @count
		BEGIN
		    RAISERROR('Что по пошло не так, проверьте созданные документы, кто-то уже успел создать поступление на основании', 16, 1)
		    RETURN
		END
		
		;
		MERGE Material.RawMaterialInvoice t
		USING (
		      	SELECT	@doc_id            doc_id,
		      			@doc_type_id       doc_type_id,
		      			LEFT(dud.edo_doc_num, 30) invoice_name,
		      			dud.edo_doc_dt     invoice_dt
		      	FROM	Synchro.DownloadUPD_Doc dud   
		      			INNER JOIN	@doc_upd d
		      				ON	dud.dud_id = d.id
		      )s
				ON t.doc_id = s.doc_id
				AND t.doc_type_id = s.doc_type_id
				AND t.invoice_name = s.invoice_name
				AND t.invoice_dt = s.invoice_dt
		WHEN MATCHED THEN 
		     UPDATE	
		     SET 	t.is_deleted = 0,
		     		t.employee_id = @employee_id,
		     		t.dt = @dt
		WHEN NOT MATCHED THEN 
		     INSERT
		     	(
		     		doc_id,
		     		doc_type_id,
		     		invoice_name,
		     		invoice_dt,
		     		dt,
		     		employee_id,
		     		ttn_name,
		     		ttn_dt
		     	)
		     VALUES
		     	(
		     		s.doc_id,
		     		s.doc_type_id,
		     		s.invoice_name,
		     		s.invoice_dt,
		     		@dt,
		     		@employee_id,
		     		s.invoice_name,
		     		s.invoice_dt
		     	)	           
		     OUTPUT	INSERTED.rmi_id,
		     		INSERTED.invoice_name,
		     		INSERTED.invoice_dt
		     INTO	@invoce_output (
		     		rmi_id,
		     		invoice_name,
		     		invoice_dt
		     	);		
		
		
		MERGE Synchro.DownloadUPD_Mapping t
		USING (
		      	SELECT	dud.esf_id,
		      			ino.rmi_id,
		      			dud.dud_id
		      	FROM	Synchro.DownloadUPD_Doc dud   
		      			INNER JOIN	@doc_upd d
		      				ON	dud.dud_id = d.id   
		      			INNER JOIN	@invoce_output ino
		      				ON	LEFT(dud.edo_doc_num,
		      			30)= ino.invoice_name
		      				AND	ino.invoice_dt = dud.edo_doc_dt
		      ) s
				ON t.esf_id = s.esf_id
		WHEN MATCHED THEN 
		     UPDATE	
		     SET 	t.rmi_id = s.rmi_id,
		     		t.dud_id = s.dud_id
		WHEN NOT MATCHED THEN 
		     INSERT
		     	(
		     		esf_id,
		     		rmi_id,
		     		dud_id
		     	)
		     VALUES
		     	(
		     		s.esf_id,
		     		s.rmi_id,
		     		s.dud_id
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
					rmid.item_number,
					rmid.rmiic_id
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
		      			gt.rmii_id,
		      			gt.gtd_id,
		      			gt.rmiic_id
		      	FROM	@goods_tab gt   
		      			INNER JOIN	@invoce_output inv_o
		      				ON	inv_o.invoice_name = gt.invoice_name
		      				AND	inv_o.invoice_dt = gt.invoice_dt
		      ) s
				ON s.rmi_id = t.rmi_id
				AND s.item_number = t.item_number
		WHEN MATCHED THEN 
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
		
		UPDATE	rmi
		SET 	employee_id = @employee_id,
				dt = @dt,
				plan_sum = v.plan_sum
		FROM	Material.RawMaterialIncome rmi
				LEFT JOIN	(
				    		SELECT	rminv.doc_id,
				    				rminv.doc_type_id,
				    				SUM(rmid.amount_with_nds) plan_sum
				    		FROM	Material.RawMaterialInvoice rminv   
				    				INNER JOIN	Material.RawMaterialInvoiceDetail rmid
				    					ON	rmid.rmi_id = rminv.rmi_id
				    		GROUP BY
				    			rminv.doc_id,
				    			rminv.doc_type_id
				    	) v
					ON	v.doc_id = rmi.doc_id
					AND	v.doc_type_id = rmi.doc_type_id
		WHERE	rmi.doc_id = @doc_id
				AND	rmi.doc_type_id = @doc_type_id
		
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