CREATE PROCEDURE [Material].[RawMaterialIncomeRelation_SetToCost]
	@doc_id INT,
	@expense_xml XML = NULL,
	@invoice_xml XML,
	@rv_bigint VARCHAR(20),
	@employee_id INT
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @doc_type_id TINYINT = 1,
	        @dt DATETIME2(0) = GETDATE(),
	        @rv ROWVERSION = CAST(CAST(@rv_bigint AS BIGINT) AS ROWVERSION),
	        @error_text VARCHAR(MAX)
	DECLARE @proc_id INT	
	EXECUTE @proc_id = History.ProcId_GetByName @procid = @@PROCID
	
	DECLARE @income_output TABLE (rv_bigint BIGINT)          	
	
	DECLARE @income_detail_output TABLE (shkrm_id INT, amount DECIMAL(19, 8))
	
	DECLARE @tab_rmid TABLE (rmid_id INT, amount DECIMAL(19, 8))
	
	DECLARE @nds_tab TABLE (rmid_id INT, shkrm_id INT, nds TINYINT)
	
	DECLARE @tab_expense AS TABLE 
	        (shkrm_id INT, rmid_id INT, rmie_id INT, amount DECIMAL(19, 8))
	
	DECLARE @tab_invoice AS TABLE 
	        (shkrm_id INT, rmid_id INT, rm_invd_id INT, invoice_name VARCHAR(30), item_number SMALLINT, amount DECIMAL(19, 8))            	
	
	SELECT	@error_text = CASE 
	      	                   --WHEN rm_inc.rv != @rv THEN 'Документ уже кто-то поменял. Перечитайте данные и попробуйте записать снова.'
	      	                   WHEN rm_inc.doc_id IS NULL THEN 'Поступления материалов с кодом ' + CAST(v.doc_id AS VARCHAR(10)) + ' не существует'
	      	                   WHEN rm_inc.is_deleted = 1 THEN 'Поступление материалов удалено'
	      	                   WHEN rm_inc.rmis_id NOT IN (1,2,3,4,5,6) THEN 'Статус документа ' + rmis.rmis_name +  ' не позволяет распределения'
	      	              END
	FROM	(VALUES(@doc_id,
			@doc_type_id))v(doc_id,
			doc_type_id)   
			LEFT JOIN	Material.RawMaterialIncome rm_inc
				ON	rm_inc.doc_id = v.doc_id
				AND	rm_inc.doc_type_id = v.doc_type_id  
			INNER JOIN Material.RawMaterialIncomeStatus rmis
				ON rmis.rmis_id = rm_inc.rmis_id			
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('(%s) данные не загружены, проверьте файл.', 16, 1, @error_text)
	    RETURN
	END
	
	INSERT @tab_expense
	  (
	    shkrm_id,
	    rmid_id,
	    rmie_id,
	    amount
	  )
	SELECT	ml.value('@shkrm_id', 'INT')     shkrm_id,
			ml.value('@rmid_id', 'INT')      rmid_id,
			ml.value('@rmie_id', 'INT')      rmie_id,
			ml.value('@amount', 'DECIMAL(19,8)') amount
	FROM	@expense_xml.nodes('items/item')x(ml)
	
	INSERT @tab_invoice
	  (
	    shkrm_id,
	    rmid_id,
	    rm_invd_id,
	    invoice_name,
	    item_number,
	    amount
	  )
	SELECT	ml.value('@shkrm_id', 'INT')     shkrm_id,
			ml.value('@rmid_id', 'INT')      rmid_id,
			ml.value('@rm_invd_id', 'INT') rm_invd_id,
			ml.value('@invoice_name', 'VARCHAR(30)') invoice_name,
			ml.value('@item_number', 'SMALLINT') item_number,
			ml.value('@amount', 'DECIMAL(19,8)') amount
	FROM	@invoice_xml.nodes('items/item')x(ml) 
	
	;
	WITH cte AS (
	     	SELECT	te.shkrm_id,
	     			te.rmid_id
	     	FROM	@tab_expense te
	     	UNION 
	     	SELECT	ti.shkrm_id,
	     			ti.rmid_id
	     	FROM	@tab_invoice ti
	     )
	
	SELECT	@error_text = 'Не найдены следующие ШК:' + CHAR(10)
	      	+ (
	      		SELECT	DISTINCT CAST(c.shkrm_id AS VARCHAR(10)) + CHAR(10)
	      		FROM	cte c   
	      				LEFT JOIN	Material.RawMaterialIncomeDetail rmid
	      					ON	rmid.shkrm_id = c.shkrm_id
	      					AND rmid.doc_id = @doc_id
        					AND rmid.doc_type_id = @doc_type_id
	      		WHERE	rmid.shkrm_id IS NULL
	      		FOR XML	PATH('')
	      	)	
	
	IF @error_text IS NULL
	    SELECT	@error_text = 'Не найдены следующие затраты:' + CHAR(10)
	          	+ (
	          		SELECT	DISTINCT CAST(te.rmie_id AS VARCHAR(10)) + CHAR(10)
	          		FROM	@tab_expense te   
	          				LEFT JOIN	Material.RawMaterialIncomeExpense rmie
	          					ON	te.rmie_id = rmie.rmie_id
	          		WHERE	rmie.rmie_id IS NULL
	          		FOR XML	PATH('')
	          	)	
	
	IF @error_text IS NULL
	    SELECT	@error_text = 'Не найдены следующие позиции в СФ:' + CHAR(10)
	          	+ (
	          		SELECT	DISTINCT 'Позиция № ' + CAST(ti.item_number AS VARCHAR(10)) + ' в СФ № ' + ti.invoice_name + '(ИД записи: ' + CAST(ti.rmid_id AS VARCHAR(10))
	          		      	+ ')' + CHAR(10)
	          		FROM	@tab_invoice ti   
	          				LEFT JOIN	Material.RawMaterialInvoiceDetail rmid
	          					ON	rmid.rmid_id = ti.rm_invd_id
	          		WHERE	rmid.rmid_id IS NULL
	          		FOR XML	PATH('')
	          	)
	          	 	
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('(%s) обнаружены ошибки.', 16, 1, @error_text)
	    RETURN
	END
		
	;
	WITH cte AS (
	     	SELECT	rmid_id,
	     			amount
	     	FROM	@tab_invoice
	     	UNION ALL 	
	     	SELECT	rmid_id,
	     			amount
	     	FROM	@tab_expense
	     )
	
	INSERT @tab_rmid
	  (
	    rmid_id,
	    amount
	  )
	SELECT	rmid_id,
			SUM(ISNULL(amount, 0))
	FROM	cte
	GROUP BY
		rmid_id
	
	INSERT INTO @nds_tab
		(
			rmid_id,
			shkrm_id,
			nds
		)
	SELECT	ti.rmid_id,
			ti.shkrm_id,
			MAX(rmid.nds) nds
	FROM	@tab_invoice ti   
			INNER JOIN	Material.RawMaterialInvoiceDetail rmid
				ON	rmid.rmid_id = ti.rm_invd_id
	GROUP BY
		ti.rmid_id,
		ti.shkrm_id
	
	BEGIN TRY
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
		
		DELETE	Material.RawMaterialIncomeExpenseRelationDetail
		WHERE	doc_id = @doc_id
				AND	doc_type_id = @doc_type_id
		
		DELETE	Material.RawMaterialInvoiceRelationDetail
		WHERE	doc_id = @doc_id
				AND	doc_type_id = @doc_type_id
		
		INSERT Material.RawMaterialIncomeExpenseRelationDetail
		  (
		    rmid_id,
		    rmie_id,
		    amount,
		    doc_id,
		    doc_type_id
		  )
		SELECT	te.rmid_id,
				te.rmie_id,
				te.amount,
				@doc_id          doc_id,
				@doc_type_id     doc_type_id
		FROM	@tab_expense     te
		
		INSERT Material.RawMaterialInvoiceRelationDetail
		  (
		    rmid_id,
		    rm_invd_id,
		    amount,
		    doc_id,
		    doc_type_id
		  )
		SELECT	ti.rmid_id,
				ti.rm_invd_id,
				ti.amount,
				@doc_id          doc_id,
				@doc_type_id     doc_type_id
		FROM	@tab_invoice     ti
		
		UPDATE	rmid
		SET 	dt = @dt,
				employee_id = @employee_id,
				amount = tr.amount,
				nds = ISNULL(nt.nds, rmid.nds)		
				OUTPUT	INSERTED.shkrm_id,
						INSERTED.amount
				INTO	@income_detail_output (
						shkrm_id,
						amount
					)
		FROM	Material.RawMaterialIncomeDetail rmid
				INNER JOIN	@tab_rmid tr
					ON	rmid.rmid_id = tr.rmid_id
				LEFT JOIN @nds_tab nt ON nt.rmid_id = rmid.rmid_id
							
		UPDATE	sma
		SET 	amount = ido.amount					
				OUTPUT	INSERTED.shkrm_id,		   		
		   			INSERTED.stor_unit_residues_okei_id,
		   			INSERTED.stor_unit_residues_qty,
		   			INSERTED.amount,
		   			INSERTED.gross_mass,	   		
		   			@proc_id,
		   			@dt,
		   			@employee_id
		   		
			   INTO	History.SHKRawMaterialAmount (
		   			shkrm_id,		   		
		   			stor_unit_residues_okei_id,
		   			stor_unit_residues_qty,
		   			amount,
		   			gross_mass,
		   			proc_id,
		   			dt,
		   			employee_id		   		
		   		)
		FROM	Warehouse.SHKRawMaterialAmount sma
				INNER JOIN	@income_detail_output ido
					ON	ido.shkrm_id = sma.shkrm_id 
		
		UPDATE	smi
		SET 	nds = nt.nds
		    	OUTPUT	INSERTED.shkrm_id,
		    			INSERTED.doc_id,
		    			INSERTED.doc_type_id,
		    			INSERTED.suppliercontract_id,
		    			INSERTED.rmt_id,
		    			INSERTED.art_id,
		    			INSERTED.color_id,
		    			INSERTED.su_id,
		    			@dt,
		    			@employee_id,
		    			INSERTED.frame_width,
		    			@proc_id,
		    			INSERTED.nds,
		    			INSERTED.tissue_density
		    	INTO	History.SHKRawMaterialInfo (
		    			shkrm_id,
		    			doc_id,
		    			doc_type_id,
		    			suppliercontract_id,
		    			rmt_id,
		    			art_id,
		    			color_id,
		    			su_id,
		    			dt,
		    			employee_id,
		    			frame_width,
		    			proc_id,
		    			nds,
		    			tissue_density
		    		)
		FROM	Warehouse.SHKRawMaterialInfo smi
				INNER JOIN	@nds_tab nt
					ON	nt.shkrm_id = smi.shkrm_id
		WHERE	nt.nds != smi.nds
		
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