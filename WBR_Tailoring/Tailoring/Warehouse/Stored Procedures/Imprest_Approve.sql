CREATE PROCEDURE [Warehouse].[Imprest_Approve]
	@imprest_id INT,
	@shkrm_xml XML,
	@sample_xml XML,
	@employee_id INT
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @dt DATETIME2(0) = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	
	DECLARE @shkrm_tab TABLE(shkrm_id INT, amount DECIMAL(15, 2))
	DECLARE @sample_tab TABLE(sample_id INT, amount DECIMAL(15, 2))
	DECLARE @cash_sum DECIMAL(15, 2)
	DECLARE @proc_id INT
	EXECUTE @proc_id = History.ProcId_GetByName @procid = @@PROCID
	
	DECLARE @imprest_employee_id INT
	DECLARE @currency_id INT = 1
	DECLARE @comment VARCHAR(500)
	DECLARE @edit_employee_id INT
	DECLARE @cfo_id INT = 376
	DECLARE @source_type_id INT = 3
	DECLARE @source_id INT
	DECLARE @context INT = 3
	
	DECLARE @office_id INT
	DECLARE @doc_dt DATETIME2(0) 
	DECLARE @upload_doc_type_id TINYINT = 5
	DECLARE @upload_buh_detail     TABLE (rmt_id INT NOT NULL, nds TINYINT NOT NULL, amount DECIMAL(9, 2) NOT NULL)
	
	SELECT	@error_text = CASE 
	      	                   WHEN i.imprest_id IS NULL THEN 'Списания в подотчет с кодом ' + CAST(v.imprest_id AS VARCHAR(10)) + ' не существует'
	      	                   WHEN i.approve_dt IS NOT NULL THEN 'Списание в подотчет № ' + CAST(v.imprest_id AS VARCHAR(10)) +
	      	                        ' уже утверждено.'
	      	                   ELSE NULL
	      	              END,
			@imprest_employee_id     = i.imprest_employee_id,
			@comment                 = i.comment,
			@edit_employee_id        = i.edit_employee_id,
			@source_id               = i.imprest_id,
			@office_id				 = i.imprest_office_id,
			@doc_dt					 = i.create_dt
	FROM	(VALUES(@imprest_id))v(imprest_id)   
			LEFT JOIN	Warehouse.Imprest i   
				ON	i.imprest_id = v.imprest_id
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	INSERT INTO @shkrm_tab
		(
			shkrm_id,
			amount
		)
	SELECT	ml.value('@shkrm[1]', 'int'),
			ml.value('@amount[1]', 'decimal(15,2)')
	FROM	@shkrm_xml.nodes('root/det')x(ml)
	
	INSERT INTO @sample_tab
		(
			sample_id,
			amount
		)
	SELECT	ml.value('@sample[1]', 'int'),
			ml.value('@amount[1]', 'decimal(15,2)')
	FROM	@sample_xml.nodes('root/det')x(ml)
	
	SELECT	@error_text = CASE 
	      	                   WHEN dt.shkrm_id IS NULL THEN 'Некорректный XML ШК'
	      	                   WHEN dt.amount IS NULL THEN 'Некорректный XML ШК'
	      	                   WHEN dt.shkrm_id IS NOT NULL AND sm.shkrm_id IS NULL THEN 'Штрихкода ' + CAST(dt.shkrm_id AS VARCHAR(10)) + 'не существует'
	      	                   WHEN sm.shkrm_id IS NOT NULL AND smai.shkrm_id IS NULL THEN 'Штрихкод ' + CAST(dt.shkrm_id AS VARCHAR(10)) +
	      	                        'не существует'
	      	                   WHEN sm.shkrm_id IS NOT NULL AND smai.shkrm_id IS NOT NULL AND sms.shkrm_id IS NULL THEN 'Штрихкод ' + CAST(dt.shkrm_id AS VARCHAR(10)) 
	      	                        + 'не имеет статуса.'
	      	                   WHEN sm.shkrm_id IS NOT NULL AND smai.shkrm_id IS NOT NULL AND isr.shkrm_id IS NULL THEN 'Штрихкод ' + CAST(dt.shkrm_id AS VARCHAR(10)) 
	      	                        + ' не записан в документе.'
	      	                   WHEN isr.stor_unit_residues_qty != smai.stor_unit_residues_qty THEN 'У штрихкода ' + CAST(dt.shkrm_id AS VARCHAR(10)) 
	      	                        + ' с момента добавления в документ, изменилось количество актуального остатка.'
	      	                   WHEN isr.stor_unit_residues_okei_id != smai.stor_unit_residues_okei_id THEN 'У штрихкода ' + CAST(dt.shkrm_id AS VARCHAR(10)) 
	      	                        + ' с момента добавления в документ, изменилась единица хранения остатка.'
	      	                   WHEN isr.shkrm_id IS NOT NULL AND sma.final_dt IS NULL THEN 'У штрихкода ' + CAST(dt.shkrm_id AS VARCHAR(10)) 
	      	                        + ' не закрыта стоимость.'
	      	                   WHEN dt.amount != ROUND(sma.amount * isr.stor_unit_residues_qty / sma.stor_unit_residues_qty, 2) THEN 'У штрихкода ' + CAST(dt.shkrm_id AS VARCHAR(10)) 
	      	                        +
	      	                        + ' с момента предпросмотра, изменилась стомость'
	      	                   ELSE NULL
	      	              END
	FROM	@shkrm_tab dt   
			LEFT JOIN	Warehouse.SHKRawMaterial sm
				ON	sm.shkrm_id = dt.shkrm_id   
			LEFT JOIN	Warehouse.SHKRawMaterialActualInfo smai
				ON	smai.shkrm_id = sm.shkrm_id   
			LEFT JOIN	Warehouse.SHKRawMaterialState sms
				ON	sms.shkrm_id = sm.shkrm_id   
			LEFT JOIN	Warehouse.ImprestShkRM isr
				ON	isr.shkrm_id = sm.shkrm_id
				AND	isr.imprest_id = @imprest_id   
			LEFT JOIN	Warehouse.SHKRawMaterialAmount sma
				ON	sma.shkrm_id = isr.shkrm_id
	WHERE	dt.shkrm_id IS NULL
			OR dt.amount IS NULL
			OR	sm.shkrm_id IS NULL
			OR	smai.shkrm_id IS NULL
			OR	sms.shkrm_id IS NULL
			OR	isr.shkrm_id IS NULL
			OR	isr.stor_unit_residues_qty != smai.stor_unit_residues_qty
			OR	isr.stor_unit_residues_okei_id != smai.stor_unit_residues_okei_id
			OR	sma.final_dt IS NULL
			OR	dt.amount != ROUND(sma.amount * isr.stor_unit_residues_qty / sma.stor_unit_residues_qty, 2)
	
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	SET @error_text = 'Для штрихкодов ' + (
	    	SELECT	CAST(isr.shkrm_id AS VARCHAR(10)) + '; '
	    	FROM	Warehouse.ImprestShkRM isr   
	    			LEFT JOIN	@shkrm_tab dt
	    				ON	dt.shkrm_id = isr.shkrm_id
	    	WHERE	isr.imprest_id = @imprest_id
	    			AND	dt.shkrm_id IS NULL
	    	FOR XML	PATH('')
	    ) + ' не передеана информация о просмотренной стоимости.'
	
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	SELECT	@error_text = CASE 
	      	                   WHEN dt.sample_id IS NULL THEN 'Некорректный XML макетов/образцов'
	      	                   WHEN dt.amount IS NULL THEN 'Некорректный XML макетов/образцов'
	      	                   WHEN dt.sample_id IS NOT NULL AND s.sample_id IS NULL THEN 'Макета/образца с кодом ' + CAST(dt.sample_id AS VARCHAR(10)) +
	      	                        'не существует'
	      	                   WHEN s.sample_id IS NOT NULL AND isa.sample_id IS NULL THEN 'Макета/образца с кодом ' + CAST(dt.sample_id AS VARCHAR(10)) +
	      	                        ' нет в документе'
	      	                   WHEN oa.is_not_final_amount = 1 THEN 'У макета/образца с кодом ' + CAST(dt.sample_id AS VARCHAR(10)) +
	      	                        ' есть ШК без конечной стоимости.'
	      	                   WHEN oa.is_not_close = 1 THEN 'Макета/образца с кодом ' + CAST(dt.sample_id AS VARCHAR(10)) +
	      	                        ' не закончен'
	      	                   WHEN dt.amount != ROUND(oa.sum_amount / oa_cs.cnt_sample, 2) THEN 'У макета/образца с кодом ' + CAST(dt.sample_id AS VARCHAR(10)) 
	      	                        +
	      	                        ' с момента предпросмотра, изменилась стоимость'
	      	                   ELSE NULL
	      	              END
	FROM	@sample_tab dt   
			LEFT JOIN	Manufactory.[Sample] s   
			INNER JOIN	Manufactory.TaskSample ts
				ON	ts.task_sample_id = s.task_sample_id
				ON	s.sample_id = dt.sample_id   
			LEFT JOIN	Warehouse.ImprestSample isa
				ON	isa.sample_id = s.sample_id
				AND	isa.imprest_id = @imprest_id   
			OUTER APPLY (
			      	SELECT	COUNT(s2.sample_id) cnt_sample
			      	FROM	Manufactory.[Sample] s2
			      	WHERE	s2.task_sample_id = ts.task_sample_id
			      			AND	s2.is_deleted = 0
			      ) oa_cs
	OUTER APPLY (
	      	SELECT	SUM(sma.amount * (mis.stor_unit_residues_qty - ISNULL(mis.return_stor_unit_residues_qty, 0)) / sma.stor_unit_residues_qty) sum_amount,
	      			MAX(CASE WHEN sma.final_dt IS NULL THEN 1 ELSE 0 END) is_not_final_amount,
	      			MAX(CASE WHEN mis.return_stor_unit_residues_qty IS NULL THEN 1 ELSE 0 END) is_not_close
	      	FROM	Warehouse.MaterialInSketch mis   
	      			INNER JOIN	Warehouse.SHKRawMaterialAmount sma
	      				ON	sma.shkrm_id = mis.shkrm_id
	      	WHERE	mis.task_sample_id = ts.task_sample_id
	      ) oa
	WHERE	dt.sample_id IS NULL
			OR dt.amount IS NULL
			OR	s.sample_id IS NULL
			OR	isa.sample_id IS NULL
			OR	oa.is_not_final_amount = 1
			OR	oa.is_not_close = 1
			OR	dt.amount != ROUND(oa.sum_amount / oa_cs.cnt_sample, 2)
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	SET @error_text = 'Для макетов/образцов с кодами ' + (
	    	SELECT	CAST(isa.sample_id AS VARCHAR(10)) + '; '
	    	FROM	Warehouse.ImprestSample isa   
	    			LEFT JOIN	@sample_tab dt
	    				ON	dt.sample_id = isa.sample_id
	    	WHERE	isa.imprest_id = @imprest_id
	    			AND	dt.sample_id IS NULL
	    	FOR XML	PATH('')
	    ) + ' не передеана информация о просмотренной стоимости.'
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	
	SELECT	@cash_sum = SUM(v.amount)
	FROM	(SELECT	srt.amount
	    	 FROM	@shkrm_tab srt
	    	UNION ALL
	    	SELECT	samt.amount
	    	FROM	@sample_tab samt
	    	UNION ALL
	    	SELECT	ism.other_amount
	    	FROM	Warehouse.ImprestSample ism
	    	WHERE	ism.imprest_id = @imprest_id
	    	UNION ALL
	    	SELECT	iod.iod_amount
	    	FROM	Warehouse.ImprestOtherDetail iod
	    	WHERE	iod.imprest_id = @imprest_id)v(amount)
	
	
	;
	WITH cte AS
		(
			SELECT	rmt.rmt_id,
					rmt.rmt_pid,
					rmt.rmt_id root_rmt_id
			FROM	Material.RawMaterialType rmt
			WHERE	rmt.rmt_pid IS NULL 
			UNION ALL
			SELECT	rmt.rmt_id,
					rmt.rmt_pid,
					c.root_rmt_id root_rmt_id
			FROM	Material.RawMaterialType rmt   
					INNER JOIN	cte c
						ON	c.rmt_id = rmt.rmt_pid
		)
	INSERT INTO @upload_buh_detail
		(
			rmt_id,
			nds,
			amount
		)
	SELECT	c.root_rmt_id,
			smi.nds,
			SUM(isr.stor_unit_residues_qty * (sma.amount / sma.stor_unit_residues_qty)) amount
	FROM	cte c   
			INNER JOIN	Warehouse.SHKRawMaterialInfo smi
				ON	smi.rmt_id = c.rmt_id   
			INNER JOIN	Warehouse.ImprestShkRM isr
				ON	isr.shkrm_id = smi.shkrm_id   
			INNER JOIN	Warehouse.SHKRawMaterialAmount sma
				ON	sma.shkrm_id = isr.shkrm_id
	WHERE	isr.imprest_id = @imprest_id
		AND isr.doc_type_id = 1
		AND c.root_rmt_id != 144
	GROUP BY
		c.root_rmt_id,
		smi.nds		
	
	BEGIN TRY
		BEGIN TRANSACTION
		
		UPDATE	Warehouse.Imprest
		SET 	is_deleted = 0,
				approve_employee_id = @employee_id,
				approve_dt = @dt,
				cash_sum = @cash_sum
		WHERE	imprest_id = @imprest_id
				AND	approve_dt IS NULL
		
		IF @@ROWCOUNT = 0
		BEGIN
		    RAISERROR('Что-то пошло не так, кто-то уже утвердил документ', 16, 1)
		    RETURN
		END
		
		UPDATE	isr
		SET 	amount = dt.amount
		FROM	Warehouse.ImprestShkRM isr
				INNER JOIN	@shkrm_tab dt
					ON	dt.shkrm_id = isr.shkrm_id
					AND	isr.imprest_id = @imprest_id
		
		UPDATE	isa
		SET 	shkrm_sample_amount = dt.amount
		FROM	Warehouse.ImprestSample isa
				INNER JOIN	@sample_tab dt
					ON	dt.sample_id = isa.sample_id
					AND	isa.imprest_id = @imprest_id
		
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
		
		--INSERT INTO SyncFinance.Fine
		--	(
		--		imprest_employee_id,
		--		cash_sum,
		--		currency_id,
		--		comment,
		--		is_deleted,
		--		edit_employee_id,
		--		approve_employee_id,
		--		cfo_id,
		--		imprest_cfo_id,
		--		source_type_id,
		--		source_id,
		--		context
		--	)
		--VALUES
		--	(
		--		@imprest_employee_id,
		--		@cash_sum,
		--		@currency_id,
		--		@comment,
		--		0,
		--		@edit_employee_id,
		--		@employee_id,
		--		@cfo_id,
		--		NULL,
		--		@source_type_id,
		--		@source_id,
		--		@context
		--	)
			
		--IF EXISTS(SELECT 1 FROM @upload_buh_detail ubd)
		--BEGIN
		--	DELETE FROM Synchro.UploadBuh_DocDetail
		--	WHERE doc_id = @imprest_id AND upload_doc_type_id = @upload_doc_type_id
		
		--	INSERT INTO Synchro.UploadBuh_DocDetail
		--		(
		--			doc_id,
		--			upload_doc_type_id,
		--			rmt_id,
		--			nds,
		--			amount
		--		)
		--	SELECT	@imprest_id,
		--			@upload_doc_type_id,
		--			ubd.rmt_id,
		--			ubd.nds,
		--			ubd.amount
		--	FROM	@upload_buh_detail ubd
		
		--	DELETE FROM Synchro.UploadBuh_Doc
		--	WHERE doc_id = @imprest_id AND upload_doc_type_id = @upload_doc_type_id
	
		--	INSERT INTO Synchro.UploadBuh_Doc
		--	(
		--		doc_id,
		--		upload_doc_type_id,
		--		suppliercontract_code,
		--		supplier_id,
		--		is_deleted,
		--		office_id,
		--		doc_dt
		--	)
		--	VALUES
		--	(
		--		@imprest_id,
		--		@upload_doc_type_id,
		--		NULL,
		--		NULL,
		--		0,
		--		@office_id,
		--		@doc_dt
		--	)
		--END
			
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