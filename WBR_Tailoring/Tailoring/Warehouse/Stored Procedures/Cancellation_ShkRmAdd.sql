CREATE PROCEDURE [Warehouse].[Cancellation_ShkRmAdd]
	@cancellation_id INT,
	@shkrm_id INT,
	@employee_id INT
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @dt dbo.SECONDSTIME = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	DECLARE @proc_id INT
	DECLARE @shkrm_state_dst INT = 13
	DECLARE @cancellation_shkrm_output TABLE (csrm_id INT)
	
	EXECUTE @proc_id = History.ProcId_GetByName @procid = @@PROCID	
	
	SELECT	@error_text = CASE 
	      	                   WHEN smai.shkrm_id IS NULL THEN 'Штрихкод ' + CAST(v.shkrm_id AS VARCHAR(10)) + ' не описан, возможно он уже списан.'
	      	                   WHEN sms.shkrm_id IS NULL THEN 'У штрихкода ' + CAST(v.shkrm_id AS VARCHAR(10)) +
	      	                        ' нет статуса, операции со штрихкодом запрещены. Обратитесь к руководителю.'
	      	                   WHEN smsg.state_src_id IS NULL THEN 'Штрихкод ' + CAST(v.shkrm_id AS VARCHAR(10)) +
	      	                        ' в статусе ' + smsd.state_name +
	      	                        '. Переход в статус ' + smsd2.state_name + ' запрещен.'
	      	                   WHEN smr.shkrm_id IS NOT NULL THEN 'Списывать нельзя, есть резерв'
	      	                   WHEN csr.csrm_id IS NOT NULL THEN 'Штрихкод ' + CAST(v.shkrm_id AS VARCHAR(10)) + ' уже запикан в документ.'
	      	                   WHEN ISNULL(rmtlc.stor_unit_residues_qty, 0) = 0 THEN 'Материал ' + rmt.rmt_name + 
	      	                        ' не имеет лимита списания, обратитесь к руководителю.'
	      	                   WHEN rmtlc.stor_unit_residues_qty IS NOT NULL AND rmtlc.stor_unit_residues_qty < ISNULL(oa_not_cancel.qty, 0) THEN 'Материал ' + 
	      	                        rmt.rmt_name + ' уже списан в количестве ' + CAST(ISNULL(oa_not_cancel.qty, 0) AS VARCHAR(10)) + 
	      	                        ' , что превышает установленный лимит списания, в количестве ' + CAST(rmtlc.stor_unit_residues_qty AS VARCHAR(10)) +
	      	                        ' . обратитесь к руководителю.'
	      	                   ELSE NULL
	      	              END
	FROM	(VALUES(@shkrm_id))v(shkrm_id)   
			LEFT JOIN	Warehouse.SHKRawMaterialActualInfo smai
				ON	smai.shkrm_id = v.shkrm_id   
			LEFT JOIN	Warehouse.SHKRawMaterialState sms   
			INNER JOIN	Warehouse.SHKRawMaterialStateDict smsd
				ON	smsd.state_id = sms.state_id
				ON	sms.shkrm_id = smai.shkrm_id   
			LEFT JOIN	Warehouse.SHKRawMaterialStateGraph smsg
				ON	sms.state_id = smsg.state_src_id
				AND	smsg.state_dst_id = @shkrm_state_dst   
			LEFT  JOIN	Warehouse.SHKRawMaterialStateDict smsd2
				ON	smsd2.state_id = @shkrm_state_dst   
			LEFT JOIN	Warehouse.SHKRawMaterialReserv smr
				ON	smr.shkrm_id = smai.shkrm_id   
			LEFT JOIN	Warehouse.CancellationShkRM csr
				ON	csr.shkrm_id = v.shkrm_id
				AND	csr.cancellation_id = @cancellation_id   
			LEFT JOIN	Material.RawMaterialTypeLimitCancellation rmtlc
				ON	rmtlc.rmt_id = smai.rmt_id   
			LEFT JOIN	Material.RawMaterialType rmt
				ON	rmt.rmt_id = smai.rmt_id   
			OUTER APPLY (
			      	SELECT	SUM(csr2.stor_unit_residues_qty) qty
			      	FROM	Warehouse.CancellationShkRM csr2   
			      			INNER JOIN	Warehouse.Cancellation c
			      				ON	c.cancellation_id = csr2.cancellation_id
			      	WHERE	c.close_dt IS NULL
			      			AND	csr2.rmt_id = smai.rmt_id
			      ) oa_not_cancel
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	SELECT	@error_text = CASE 
	      	                   WHEN c.cancellation_id IS NULL THEN 'Документа списания с номером ' + CAST(v.cancellation_id AS VARCHAR(10)) +
	      	                        ' не существует.'
	      	                   WHEN c.close_dt IS NOT NULL THEN 'Документ закрыт, добавлять ШК запрещено.'
	      	                   ELSE NULL
	      	              END
	FROM	(VALUES(@cancellation_id))v(cancellation_id)   
			LEFT JOIN	Warehouse.Cancellation c
				ON	c.cancellation_id = v.cancellation_id 
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	BEGIN TRY
		BEGIN TRANSACTION
		
		INSERT INTO Warehouse.CancellationShkRM
		  (
		    cancellation_id,
		    shkrm_id,
		    doc_id,
		    doc_type_id,
		    rmt_id,
		    art_id,
		    color_id,
		    su_id,
		    suppliercontract_id,
		    okei_id,
		    qty,
		    stor_unit_residues_okei_id,
		    stor_unit_residues_qty,
		    nds,
		    dt,
		    employee_id,
		    is_deleted,
		    frame_width,
		    is_defected
		  )OUTPUT	INSERTED.csrm_id
		   INTO	@cancellation_shkrm_output (
		   		csrm_id
		   	)
		SELECT	@cancellation_id,
				smai.shkrm_id,
				smai.doc_id,
				smai.doc_type_id,
				smai.rmt_id,
				smai.art_id,
				smai.color_id,
				smai.su_id,
				smai.suppliercontract_id,
				smai.okei_id,
				smai.qty,
				smai.stor_unit_residues_okei_id,
				smai.stor_unit_residues_qty,

				smai.nds,
				@dt,
				@employee_id,
				0,
				smai.frame_width,
				smai.is_defected
		FROM	Warehouse.SHKRawMaterialActualInfo smai		
		WHERE	smai.shkrm_id = @shkrm_id
		
		DELETE	
		FROM	Warehouse.SHKRawMaterialActualInfo
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
		WHERE	shkrm_id = @shkrm_id
		
		DELETE	
		FROM	Warehouse.SHKRawMaterialDefectDescr
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
		WHERE	shkrm_id = @shkrm_id
		
		INSERT INTO History.SHKRawMaterialState
		  (
		    shkrm_id,
		    state_id,
		    dt,
		    employee_id,
		    proc_id
		  )
		VALUES
		  (
		    @shkrm_id,
		    @shkrm_state_dst,
		    @dt,
		    @employee_id,
		    @proc_id
		  )
		
		DELETE	
		FROM	Warehouse.SHKRawMaterialState
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
		WHERE	shkrm_id = @shkrm_id
		
		DELETE	
		FROM	Warehouse.SHKRawMaterialOnPlace
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
		WHERE	shkrm_id = @shkrm_id
		
		DELETE	
		FROM	Warehouse.SHKRawMaterialReserv
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
		WHERE	shkrm_id = @shkrm_id
		
		COMMIT TRANSACTION
		
		SELECT	csr.shkrm_id,
				a.art_name,
				rmt.rmt_name,
				cc.color_name,
				s.supplier_name,
				o.symbol                     okei_symbol,
				csr.qty,
				o2.symbol                    stor_unit_residues_okei_symbol,
				csr.stor_unit_residues_qty,
				sma.amount * csr.stor_unit_residues_qty / sma.stor_unit_residues_qty amount,
				csr.frame_width,
				csr.is_defected,
				csr.employee_id,
				CAST(csr.dt AS DATETIME)     dt
		FROM	Warehouse.CancellationShkRM csr   
				INNER JOIN	@cancellation_shkrm_output csro
					ON	csr.csrm_id = csro.csrm_id   
				INNER JOIN	Material.Article a
					ON	a.art_id = csr.art_id   
				INNER JOIN	Material.RawMaterialType rmt
					ON	rmt.rmt_id = csr.rmt_id   
				INNER JOIN	Material.ClothColor cc
					ON	cc.color_id = csr.color_id   
				INNER JOIN	Qualifiers.OKEI o
					ON	o.okei_id = csr.okei_id   
				INNER JOIN	Qualifiers.OKEI o2
					ON	o2.okei_id = csr.stor_unit_residues_okei_id   
				INNER JOIN	Suppliers.SupplierContract sc
					ON	sc.suppliercontract_id = csr.suppliercontract_id   
				INNER JOIN	Suppliers.Supplier s
					ON	s.supplier_id = sc.supplier_id
				INNER JOIN Warehouse.SHKRawMaterialAmount sma
					ON sma.shkrm_id = csr.shkrm_id
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