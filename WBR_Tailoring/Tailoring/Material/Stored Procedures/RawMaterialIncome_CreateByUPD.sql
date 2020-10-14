CREATE PROCEDURE [Material].[RawMaterialIncome_CreateByUPD]
	@supply_dt DATE,
	@employee_id INT,
	@doc_upd dbo.List READONLY
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @doc_id INT,
	        @dt DATETIME2(0) = GETDATE(),
	        @supplier_id INT,
	        @create_status INT = 1,
	        @doc_type_id TINYINT = 1,
	        @error_text VARCHAR(MAX),
	        @suppliercontract_id INT,
	        @plan_sum DECIMAL(18, 2),
	        @count INT
	
	DECLARE @income_output TABLE (
	        	doc_id INT NOT NULL,
	        	doc_type_id TINYINT NOT NULL,
	        	rmis_id INT NOT NULL,
	        	dt DATETIME2(0) NOT NULL,
	        	employee_id INT NOT NULL,
	        	supplier_id INT NOT NULL,
	        	suppliercontract_id INT NOT NULL,
	        	supply_dt DATETIME2(0) NOT NULL,
	        	is_deleted BIT NOT NULL,
	        	goods_dt DATETIME2(0) NULL,
	        	comment VARCHAR(200) NULL,
	        	payment_comment VARCHAR(200) NULL,
	        	plan_sum DECIMAL(18, 2) NULL,
	        	scan_load_dt DATETIME2(0) NULL,
	        	rv_bigint BIGINT NOT NULL
	        )  
	
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
	        	okei_code VARCHAR(10),
	        	okei_id INT NULL,
	        	rmii_id INT NULL,
	        	gtd_id INT NULL,
	        	edo_country_id INT NULL,
	        	country_id INT NULL,
	        	is_deleted BIT NULL
	        )
	
	IF @supply_dt IS NULL
	BEGIN
	    RAISERROR('Не заполнена предполагаемая дата поставки.', 16, 1)
	    RETURN
	END
	
	
	SELECT	@error_text = CASE 
	      	                   WHEN COUNT(1) = 0 THEN 'Не передано ни одного УПД'
	      	                   WHEN COUNT(d.id) != COUNT(dud.dud_id) THEN 'Передан некорректный список УПД'
	      	                   WHEN COUNT(DISTINCT dud.suppliercontract_id) > 1 THEN 'Выбранные УПД должны быть с одним договором'
	      	                   WHEN COUNT(DISTINCT dud.suppliercontract_id) = 1 AND MAX(ISNULL(sc.suppliercontract_id, 0)) = 0 THEN 
	      	                        'Договор УПД отсутствует в базе производства'
	      	                   WHEN MAX(ISNULL(dum.esf_id, 0)) != 0 THEN 'На УПД с кодом ' + CAST(MAX(ISNULL(dum.esf_id, 0)) AS VARCHAR(10)) + 
	      	                        ' уже созано поступление.'
	      	                   WHEN COUNT(dud.esf_id) != COUNT(DISTINCT dud.esf_id) THEN 'Не уникальный набор документов'
	      	                   WHEN COUNT(dud.edo_doc_num) != COUNT(DISTINCT LEFT(dud.edo_doc_num, 30)) THEN 'Не уникальные номера документов'
	      	                   WHEN MAX(ISNULL(dud.dt_proc, '')) != '' THEN 'Выбранные УПД содержат уже обработанные строки.'
	      	                   ELSE NULL
	      	              END,
			@suppliercontract_id = MAX(ISNULL(sc.suppliercontract_id, 0)),
			@supplier_id = MAX(ISNULL(sc.supplier_id, 0)),
			@count = COUNT(1)
	FROM	@doc_upd d   
			LEFT JOIN	Synchro.DownloadUPD_Doc dud
				ON	dud.dud_id = d.id   
			LEFT JOIN	Suppliers.SupplierContract sc
				ON	sc.suppliercontract_erp_id = dud.suppliercontract_id   
			LEFT JOIN	Synchro.DownloadUPD_Mapping dum
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
			is_deleted
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
			0                               is_deleted
	FROM	@doc_upd d   
			INNER JOIN	Synchro.DownloadUPD_Doc dud
				ON	dud.dud_id = d.id   
			INNER JOIN	Synchro.DownloadUPD_DocDetail dudd
				ON	dudd.dud_id = dud.dud_id   
			LEFT JOIN	Synchro.DownloadUPD_Item dui
				ON	dui.dui_id = dudd.dui_id_item_name   
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
	
	SELECT	@plan_sum = SUM(g.amount_with_nds)
	FROM	@goods_tab g
	
	
	
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
		
		BEGIN TRANSACTION
		
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
		
		SET @doc_id = NEXT VALUE FOR Documents.RawMaterialIncomeSeq
		
		INSERT INTO Documents.DocumentID
			(
				doc_id,
				doc_type_id,
				create_dt,
				create_employee_id
			)
		VALUES
			(
				@doc_id,
				@doc_type_id,
				@dt,
				@employee_id
			)
		
		INSERT INTO Material.RawMaterialIncome
			(
				doc_id,
				doc_type_id,
				rmis_id,
				dt,
				employee_id,
				supplier_id,
				plan_sum,
				supply_dt,
				is_deleted,
				goods_dt,
				suppliercontract_id
			)OUTPUT	INSERTED.doc_id,
			 		INSERTED.doc_type_id,
			 		INSERTED.rmis_id,
			 		INSERTED.dt,
			 		INSERTED.employee_id,
			 		INSERTED.supplier_id,
			 		INSERTED.suppliercontract_id,
			 		INSERTED.supply_dt,
			 		INSERTED.is_deleted,
			 		INSERTED.goods_dt,
			 		INSERTED.comment,
			 		INSERTED.payment_comment,
			 		INSERTED.plan_sum,
			 		INSERTED.scan_load_dt,
			 		CAST(INSERTED.rv AS BIGINT)
			 INTO	@income_output (
			 		doc_id,
			 		doc_type_id,
			 		rmis_id,
			 		dt,
			 		employee_id,
			 		supplier_id,
			 		suppliercontract_id,
			 		supply_dt,
			 		is_deleted,
			 		goods_dt,
			 		comment,
			 		payment_comment,
			 		plan_sum,
			 		scan_load_dt,
			 		rv_bigint
			 	)
		VALUES
			(
				@doc_id,
				@doc_type_id,
				@create_status,
				@dt,
				@employee_id,
				@supplier_id,
				@plan_sum,
				@supply_dt,
				0,
				@supply_dt,
				@suppliercontract_id
			)
		
		INSERT History.RawMaterialIncome
			(
				doc_id,
				doc_type_id,
				rmis_id,
				dt,
				employee_id,
				supplier_id,
				suppliercontract_id,
				supply_dt,
				is_deleted,
				goods_dt,
				comment,
				payment_comment,
				plan_sum,
				scan_load_dt
			)
		SELECT	inc_o.doc_id,
				inc_o.doc_type_id,
				inc_o.rmis_id,
				inc_o.dt,
				inc_o.employee_id,
				inc_o.supplier_id,
				inc_o.suppliercontract_id,
				inc_o.supply_dt,
				inc_o.is_deleted,
				inc_o.goods_dt,
				inc_o.comment,
				inc_o.payment_comment,
				inc_o.plan_sum,
				inc_o.scan_load_dt
		FROM	@income_output inc_o 
		
		INSERT INTO Material.RawMaterialInvoice
			(
				doc_id,
				doc_type_id,
				invoice_name,
				invoice_dt,
				dt,
				employee_id,
				ttn_name, 
				ttn_dt
			)OUTPUT	INSERTED.rmi_id,
			 		INSERTED.invoice_name,
			 		INSERTED.invoice_dt
			 INTO	@invoce_output (
			 		rmi_id,
			 		invoice_name,
			 		invoice_dt
			 	)
		SELECT	@doc_id,
				@doc_type_id,
				LEFT(dud.edo_doc_num, 30) invoice_name,
				dud.edo_doc_dt invoice_dt,
				@dt,
				@employee_id,
				LEFT(dud.edo_doc_num, 30) invoice_name,
				dud.edo_doc_dt invoice_dt
		FROM	Synchro.DownloadUPD_Doc dud   
				INNER JOIN	@doc_upd d
					ON	dud.dud_id = d.id	           
		
		INSERT INTO Synchro.DownloadUPD_Mapping
			(
				esf_id,
				rmi_id,
				dud_id
			)
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
		
		INSERT INTO Material.RawMaterialInvoiceDetail
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
		SELECT	inv_o.rmi_id,
				gt.rmii_id,
				gt.price,
				gt.quantity,
				gt.amount_with_nds,
				gt.amount_nds,
				gt.amount_without_nds,
				gt.nds,
				gt.okei_id,
				gt.country_id,
				gt.gtd_id,
				gt.item_number
		FROM	@goods_tab gt   
				INNER JOIN	@invoce_output inv_o
					ON	inv_o.invoice_name = gt.invoice_name
					AND	inv_o.invoice_dt = gt.invoice_dt
		
		COMMIT TRANSACTION
		
		SELECT	inc_o.doc_id,
				inc_o.rv_bigint
		FROM	@income_output inc_o
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