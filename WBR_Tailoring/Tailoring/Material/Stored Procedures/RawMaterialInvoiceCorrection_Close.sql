CREATE PROCEDURE [Material].[RawMaterialInvoiceCorrection_Close]
	@rmic_id INT,
	@employee_id INT
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @dt DATETIME2(0) = GETDATE()
	
	DECLARE @error_text VARCHAR(MAX)
	DECLARE @proc_id INT
	DECLARE @shkrm_state_dst INT = 21
	DECLARE @shkrm_tab TABLE (shkrm_id INT)
	
	EXECUTE @proc_id = History.ProcId_GetByName @procid = @@PROCID
	
	DECLARE @suppliercontract_code VARCHAR(9)
	DECLARE @supplier_id INT 
	DECLARE @office_id INT 
	DECLARE @invoice_name VARCHAR(30)
	DECLARE @upload_doc_type_id TINYINT = 6
	DECLARE @doc_id INT
	declare @fabricator_id int
	
	DECLARE @upload_buh_invoice_detail TABLE (
	        	invoice_name VARCHAR(30) NOT NULL,
	        	invoice_dt DATE NOT NULL,
	        	rmt_id INT NOT NULL,
	        	nds TINYINT NOT NULL,
	        	amount DECIMAL(9, 2) NOT NULL,
	        	ttn_name VARCHAR(30) NULL,
	        	ttn_dt DATE NULL,
	        	invoice_id INT
	        )
	
	DECLARE @doc_dt DATETIME2(0)
	
	SELECT	@office_id = os.office_id
	FROM	Settings.OfficeSetting os
	WHERE	os.is_main_wh = 1
	
	SELECT	@error_text = CASE 
	      	                   WHEN rmic.rmic_id IS NULL THEN 'Нету документа с номером ' + CAST(v.rmic_id AS VARCHAR(10))
	      	                   WHEN rmic.close_dt IS NOT NULL THEN 'Документ уже закрыт'
	      	                   WHEN rmic.rmic_id IS NOT NULL AND ISNULL(oa.return_quantity, 0) = 0 THEN 
	      	                        'Возвращаемое количество по счетфактуре не должно быть равно 0'
	      	                   WHEN rmic.rmic_id IS NOT NULL AND oas.rmicd_id IS NULL THEN 'В документ не запикан не один ШК'
	      	                   ELSE NULL
	      	              END,
			@supplier_id = rmincm.supplier_id,
			@suppliercontract_code = sc.suppliercontract_code,
			@doc_dt = rmic.create_dt,
			@invoice_name = rmic.buch_num,
			@doc_id = rmic.rmic_id,
			@fabricator_id = rmincm.fabricator_id
	FROM	(VALUES(@rmic_id))v(rmic_id)   
			LEFT JOIN	Material.RawMaterialInvoiceCorrection rmic   
			INNER JOIN	Material.RawMaterialInvoice rmi
				ON	rmi.rmi_id = rmic.rmi_id   
			INNER JOIN	Material.RawMaterialIncome rmincm
				ON	rmincm.doc_id = rmi.doc_id
				AND	rmincm.doc_type_id = rmi.doc_type_id   
			INNER JOIN	Suppliers.SupplierContract sc
				ON	sc.suppliercontract_id = rmincm.suppliercontract_id
				ON	rmic.rmic_id = v.rmic_id   
			OUTER APPLY (
			      	SELECT	SUM(rmicid.return_quantity) return_quantity
			      	FROM	Material.RawMaterialInvoiceCorrectionInvoiceDetail rmicid
			      	WHERE	rmicid.rmic_id = rmic.rmic_id
			      ) oa
	OUTER APPLY (
	      	SELECT	TOP(1) rmicd.rmicd_id
	      	FROM	Material.RawMaterialInvoiceCorrectionDetail rmicd
	      	WHERE	rmicd.rmic_id = rmic.rmic_id
	      ) oas
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END		
	
	SET @error_text = (
	    	SELECT	CASE 
	    	      	     WHEN sms.shkrm_id IS NULL THEN 'У штрихкода ' + CAST(rmicd.shkrm_id AS VARCHAR(10)) +
	    	      	          ' нет статуса, операции со штрихкодом запрещены. Обратитесь к руководителю' + CHAR(10)
	    	      	     WHEN sms.state_id = @shkrm_state_dst THEN 'Штрихкод уже возвращен поставщику' + CHAR(10)
	    	      	     WHEN smai.shkrm_id IS NULL THEN 'Штрихкод ' + CAST(rmicd.shkrm_id AS VARCHAR(10)) +
	    	      	          ' не описан.' + CHAR(10)
	    	      	     WHEN smsg.state_src_id IS NULL THEN 'Штрихкод ' + CAST(rmicd.shkrm_id AS VARCHAR(10)) + ' в статусе ' + smsd.state_name +
	    	      	          '. Переход в статус ' + smsd2.state_name + ' запрещен.' + CHAR(10)
	    	      	     ELSE NULL
	    	      	END
	    	FROM	Material.RawMaterialInvoiceCorrectionDetail rmicd   
	    			LEFT JOIN	Warehouse.SHKRawMaterialState sms
	    				ON	sms.shkrm_id = rmicd.shkrm_id   
	    			LEFT JOIN	Warehouse.SHKRawMaterialStateDict smsd
	    				ON	smsd.state_id = sms.state_id   
	    			LEFT JOIN	Warehouse.SHKRawMaterialStateGraph smsg
	    				ON	sms.state_id = smsg.state_src_id
	    				AND	smsg.state_dst_id = @shkrm_state_dst   
	    			INNER JOIN	Warehouse.SHKRawMaterialStateDict smsd2
	    				ON	smsd2.state_id = @shkrm_state_dst   
	    			LEFT JOIN	Warehouse.SHKRawMaterialActualInfo smai
	    				ON	smai.shkrm_id = rmicd.shkrm_id
	    	WHERE	rmicd.rmic_id = @rmic_id
	    			AND	(sms.shkrm_id IS NULL OR sms.state_id = @shkrm_state_dst OR smai.shkrm_id IS NULL OR smsg.state_src_id IS NULL)
	    	FOR XML	PATH('')
	    )
	
	IF @error_text IS NOT NULL
	   AND LEN(@error_text) > 0
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	INSERT INTO @upload_buh_invoice_detail
		(
			invoice_name,
			invoice_dt,
			rmt_id,
			nds,
			amount,
			ttn_name,
			ttn_dt,
			invoice_id
		)
	SELECT	@invoice_name,
			@doc_dt,
			rmid.rmt_id,
			rmid.nds,
			SUM(ROUND(rmid.base_amount_with_nds * (rmid.return_quantity / rmid.base_quantity), 2)) amount,
			@invoice_name,
			@doc_dt,
			rmid.rmic_id
	FROM	Material.RawMaterialInvoiceCorrectionInvoiceDetail rmid
	WHERE	rmid.rmic_id = @rmic_id
	GROUP BY
		rmid.rmt_id,
		rmid.nds,
		rmid.rmic_id
	
	INSERT INTO @shkrm_tab
		(
			shkrm_id
		)
	SELECT	rmicd.shkrm_id
	FROM	Material.RawMaterialInvoiceCorrectionDetail rmicd
	WHERE	rmicd.rmic_id = @rmic_id
	
	BEGIN TRY
		BEGIN TRANSACTION 
		
		UPDATE	Material.RawMaterialInvoiceCorrection
		SET 	close_dt = @dt,
				close_employee_id = @employee_id
		WHERE	rmic_id = @rmic_id
		
		DELETE	
		FROM	Synchro.UploadBuh_DocInvoiceDetail
		WHERE	doc_id = @doc_id
				AND	upload_doc_type_id = @upload_doc_type_id		
		
		IF ISNULL(@fabricator_id, 1) = 1
		BEGIN		
		INSERT INTO Synchro.UploadBuh_DocInvoiceDetail
			(
				doc_id,
				upload_doc_type_id,
				invoice_name,
				invoice_dt,
				rmt_id,
				nds,
				amount,
				ttn_name,
				ttn_dt
			)
		SELECT	@doc_id,
				@upload_doc_type_id,
				id.invoice_name,
				id.invoice_dt,
				id.rmt_id,
				id.nds,
				id.amount,
				id.ttn_name,
				id.ttn_dt
		FROM	@upload_buh_invoice_detail id
		END
		
		DELETE	
		FROM	Synchro.UploadBuh_Doc
		WHERE	doc_id = @doc_id
				AND	upload_doc_type_id = @upload_doc_type_id
		
		IF EXISTS(
		   	SELECT	1
		   	FROM	@upload_buh_invoice_detail
		) AND ISNULL(@fabricator_id, 1) = 1
		BEGIN
		    INSERT INTO Synchro.UploadBuh_Doc
		    	(
		    		doc_id,
		    		upload_doc_type_id,
		    		suppliercontract_code,
		    		supplier_id,
		    		is_deleted,
		    		office_id,
		    		doc_dt
		    	)
		    VALUES
		    	(
		    		@doc_id,
		    		@upload_doc_type_id,
		    		@suppliercontract_code,
		    		@supplier_id,
		    		0,
		    		@office_id,
		    		@doc_dt
		    	)
		END
		
		UPDATE	s
		SET 	state_id = @shkrm_state_dst,
				dt = @dt,
				employee_id = @employee_id
				OUTPUT	INSERTED.shkrm_id,
						INSERTED.state_id,
						INSERTED.dt,
						INSERTED.employee_id,
						@proc_id
				INTO	History.SHKRawMaterialState (
						shkrm_id,
						state_id,
						dt,
						employee_id,
						proc_id
					)
		FROM	Warehouse.SHKRawMaterialState s
		WHERE	EXISTS(
		     		SELECT	1
		     		FROM	@shkrm_tab st
		     		WHERE	st.shkrm_id = s.shkrm_id
		     	)
		
		DELETE	sr		    
		      	OUTPUT	DELETED.shkrm_id,
		      			DELETED.spcvc_id,
		      			DELETED.okei_id,
		      			DELETED.quantity,
		      			@dt,
		      			@employee_id,
		      			DELETED.rmid_id,
		      			DELETED.rmodr_id,
		      			@proc_id,
		      			'D'
		      	INTO	History.SHKRawMaterialReserv (
		      			shkrm_id,
		      			spcvc_id,
		      			okei_id,
		      			quantity,
		      			dt,
		      			employee_id,
		      			rmid_id,
		      			rmodr_id,
		      			proc_id,
		      			operation
		      		)
		FROM	Warehouse.SHKRawMaterialReserv sr
		WHERE	EXISTS(
		     		SELECT	1
		     		FROM	@shkrm_tab st
		     		WHERE	st.shkrm_id = sr.shkrm_id
		     	)
		
		DELETE	smai		    
		      	OUTPUT	DELETED.shkrm_id,
		      			@dt,
		      			@employee_id,
		      			@proc_id
		      	INTO	History.SHKRawMaterialActualInfo (
		      			shkrm_id,
		      			dt,
		      			employee_id,
		      			proc_id
		      		)
		FROM	Warehouse.SHKRawMaterialActualInfo smai
		WHERE	EXISTS(
		     		SELECT	1
		     		FROM	@shkrm_tab st
		     		WHERE	st.shkrm_id = smai.shkrm_id
		     	)
		
		DELETE	smdd		    
		      	OUTPUT	DELETED.shkrm_id,
		      			NULL,
		      			@dt,
		      			@employee_id,
		      			@proc_id
		      	INTO	History.SHKRawMaterialDefectDescr (
		      			shkrm_id,
		      			descr,
		      			dt,
		      			employee_id,
		      			proc_id
		      		)
		FROM	Warehouse.SHKRawMaterialDefectDescr smdd
		WHERE	EXISTS(
		     		SELECT	1
		     		FROM	@shkrm_tab st
		     		WHERE	st.shkrm_id = smdd.shkrm_id
		     	)
		
		
		DELETE	ss	    
		      	OUTPUT	DELETED.shkrm_id,
		      			NULL,
		      			@dt,
		      			@employee_id,
		      			@proc_id
		      	INTO	History.SHKRawMaterialState (
		      			shkrm_id,
		      			state_id,
		      			dt,
		      			employee_id,
		      			proc_id
		      		)
		FROM	Warehouse.SHKRawMaterialState ss
		WHERE	EXISTS(
		     		SELECT	1
		     		FROM	@shkrm_tab st
		     		WHERE	st.shkrm_id = ss.shkrm_id
		     	)
		
		DELETE	sop
		      	
		      	OUTPUT	DELETED.shkrm_id,
		      			NULL,
		      			@dt,
		      			@employee_id,
		      			@proc_id
		      	INTO	History.SHKRawMaterialOnPlace (
		      			shkrm_id,
		      			place_id,
		      			dt,
		      			employee_id,
		      			proc_id
		      		)
		FROM	Warehouse.SHKRawMaterialOnPlace sop
		WHERE	EXISTS(
		     		SELECT	1
		     		FROM	@shkrm_tab st
		     		WHERE	st.shkrm_id = sop.shkrm_id
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
		
		RAISERROR('Ошибка %d в строке %d  %s', @esev, @estate, @ErrNum, @Line, @Mess) 
		WITH LOG;
	END CATCH
GO	