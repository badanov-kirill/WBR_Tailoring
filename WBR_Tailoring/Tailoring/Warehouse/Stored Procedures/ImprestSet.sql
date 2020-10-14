CREATE PROCEDURE [Warehouse].[ImprestSet]
	@imprest_id INT = NULL,
	@shkrm_xml XML,
	@sample_xml XML,
	@other_xml XML,
	@imprest_office_id INT,
	@imprest_employee_id INT,
	@comment VARCHAR(500) = NULL,
	@employee_id INT
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @dt DATETIME2(0) = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	
	DECLARE @shkrm_tab TABLE(shkrm_id INT)
	DECLARE @sample_tab TABLE(sample_id INT, comment VARCHAR(200), other_amount DECIMAL(15, 2))
	DECLARE @other_tab TABLE(iod_num SMALLINT, descr VARCHAR(200), amount DECIMAL(15, 2))
	DECLARE @imprest_out TABLE (imprest_id INT)
	DECLARE @shkrm_state_dst INT = 20
	DECLARE @proc_id INT
	EXECUTE @proc_id = History.ProcId_GetByName @procid = @@PROCID
	
	IF @imprest_id IS NOT NULL
	BEGIN
	    SELECT	@error_text = CASE 
	          	                   WHEN i.imprest_id IS NULL THEN 'Списания в подотчет с кодом ' + CAST(v.imprest_id AS VARCHAR(10)) + ' не существует'
	          	                   WHEN i.approve_dt IS NOT NULL THEN 'Списание в подотчет № ' + CAST(v.imprest_id AS VARCHAR(10)) +
	          	                        ' уже закрыто, редакторовать нельзя.'
	          	                   ELSE NULL
	          	              END
	    FROM	(VALUES(@imprest_id))v(imprest_id)   
	    		LEFT JOIN	Warehouse.Imprest i
	    			ON	i.imprest_id = v.imprest_id
	    
	    IF @error_text IS NOT NULL
	    BEGIN
	        RAISERROR('%s', 16, 1, @error_text)
	        RETURN
	    END
	END
	
	IF NOT EXISTS (
	   	SELECT	1
	   	FROM	Settings.OfficeSetting os
	   	WHERE	os.office_id = @imprest_office_id
	   )
	BEGIN
	    RAISERROR('Офиса с кодом %d не существует', 16, 1, @imprest_office_id)
	    RETURN
	END
	
	INSERT INTO @shkrm_tab
		(
			shkrm_id
		)
	SELECT	ml.value('@shkrm[1]', 'int')
	FROM	@shkrm_xml.nodes('root/det')x(ml)
	
	INSERT INTO @sample_tab
		(
			sample_id,
			comment,
			other_amount
		)
	SELECT	ml.value('@sample[1]', 'int'),
			ml.value('@comm[1]', 'varchar(200)'),
			ml.value('@oamount[1]', 'decimal(15,2)')
	FROM	@sample_xml.nodes('root/det')x(ml)
	
	INSERT INTO @other_tab
		(
			iod_num,
			descr,
			amount
		)
	SELECT	ml.value('@num[1]', 'smallint'),
			ml.value('@descr[1]', 'varchar(200)'),
			ml.value('@amount[1]', 'decimal(15,2)')
	FROM	@other_xml.nodes('root/det')x(ml)
	
	SELECT	@error_text = CASE 
	      	                   WHEN dt.shkrm_id IS NULL THEN 'Некорректный XML ШК'
	      	                   WHEN dt.shkrm_id IS NOT NULL AND sm.shkrm_id IS NULL THEN 'Штрихкода ' + CAST(dt.shkrm_id AS VARCHAR(10)) + 'не существует'
	      	                   WHEN sm.shkrm_id IS NOT NULL AND smai.shkrm_id IS NULL THEN 'Штрихкод ' + CAST(dt.shkrm_id AS VARCHAR(10)) +
	      	                        'не существует'
	      	                   WHEN sm.shkrm_id IS NOT NULL AND smai.shkrm_id IS NOT NULL AND sms.shkrm_id IS NULL THEN 'Штрихкод ' + CAST(dt.shkrm_id AS VARCHAR(10)) 
	      	                        + 'не имеет статуса.'
	      	                   ELSE NULL
	      	              END
	FROM	@shkrm_tab dt   
			LEFT JOIN	Warehouse.SHKRawMaterial sm
				ON	sm.shkrm_id = dt.shkrm_id   
			LEFT JOIN	Warehouse.SHKRawMaterialActualInfo smai
				ON	smai.shkrm_id = sm.shkrm_id   
			LEFT JOIN	Warehouse.SHKRawMaterialState sms
				ON	sms.shkrm_id = sm.shkrm_id
	WHERE	dt.shkrm_id IS NULL
			OR	sm.shkrm_id IS NULL
			OR	smai.shkrm_id IS NULL
			OR	sms.shkrm_id IS NULL
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	SELECT	@error_text = CASE 
	      	                   WHEN dt.sample_id IS NULL THEN 'Некорректный XML макетов/образцов'
	      	                   WHEN dt.sample_id IS NOT NULL AND s.sample_id IS NULL THEN 'Макета/образца с кодом ' + CAST(dt.sample_id AS VARCHAR(10)) +
	      	                        'не существует'
	      	                   ELSE NULL
	      	              END
	FROM	@sample_tab dt   
			LEFT JOIN	Manufactory.[Sample] s
				ON	s.sample_id = dt.sample_id
	WHERE	dt.sample_id IS NULL
			OR	s.sample_id IS NULL
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	IF EXISTS (
	   	SELECT	1
	   	FROM	@other_tab ot
	   	WHERE	ot.descr IS NULL
	   			OR	ISNULL(ot.amount, 0) = 0
	   )
	BEGIN
	    RAISERROR('Некорректный XML прочих позиций', 16, 1)
	    RETURN
	END
	
	
	
	BEGIN TRY
		BEGIN TRANSACTION 
		
		IF @imprest_id IS NULL
		BEGIN
		    INSERT INTO Warehouse.Imprest
		    	(
		    		create_dt,
		    		create_employee_id,
		    		imprest_office_id,
		    		imprest_employee_id,
		    		comment,
		    		is_deleted,
		    		edit_employee_id,
		    		approve_employee_id,
		    		approve_dt,
		    		cash_sum
		    	)OUTPUT	INSERTED.imprest_id
		    	 INTO	@imprest_out (
		    	 		imprest_id
		    	 	)
		    VALUES
		    	(
		    		@dt,
		    		@employee_id,
		    		@imprest_office_id,
		    		@imprest_employee_id,
		    		@comment,
		    		0,
		    		@employee_id,
		    		NULL,
		    		NULL,
		    		NULL
		    	)
		END
		ELSE
		BEGIN
		    UPDATE	Warehouse.Imprest
		    SET 	imprest_office_id = @imprest_office_id,
		    		imprest_employee_id = @imprest_employee_id,
		    		comment = @comment,
		    		is_deleted = 0,
		    		edit_employee_id = @employee_id
		    		OUTPUT	INSERTED.imprest_id
		    		INTO	@imprest_out (
		    				imprest_id
		    			)
		    WHERE	imprest_id = @imprest_id
		    		AND	approve_dt IS NULL
		    
		    
		    
		    IF NOT EXISTS (
		       	SELECT	1
		       	FROM	@imprest_out i
		       )
		    BEGIN
		        ROLLBACK TRANSACTION
		        RAISERROR('Пока форма была открыта, документ утвердили, редактировать нельзщя', 16, 1)
		        RETURN
		    END
		END;
		
		WITH cte_target AS (
			SELECT	isr.isr_id,
					isr.imprest_id,
					isr.shkrm_id,
					isr.doc_id,
					isr.doc_type_id,
					isr.rmt_id,
					isr.art_id,
					isr.color_id,
					isr.su_id,
					isr.suppliercontract_id,
					isr.okei_id,
					isr.qty,
					isr.stor_unit_residues_okei_id,
					isr.stor_unit_residues_qty,
					isr.nds,
					isr.dt,
					isr.employee_id,
					isr.frame_width,
					isr.is_defected,
					isr.amount
			FROM	Warehouse.ImprestShkRM isr   
					INNER JOIN	@imprest_out i
						ON	i.imprest_id = isr.imprest_id
		)
		MERGE cte_target t
		USING (
		      	SELECT	smai.shkrm_id,
		      			smai.doc_id,
		      			smai.doc_type_id,
		      			smai.suppliercontract_id,
		      			smai.rmt_id,
		      			smai.art_id,
		      			smai.color_id,
		      			smai.su_id,
		      			smai.okei_id,
		      			smai.qty,
		      			smai.stor_unit_residues_okei_id,
		      			smai.stor_unit_residues_qty,
		      			smai.frame_width,
		      			smai.is_defected,
		      			smai.nds,
		      			smai.gross_mass,
		      			i.imprest_id
		      	FROM	@shkrm_tab dt   
		      			INNER JOIN	Warehouse.SHKRawMaterialActualInfo smai
		      				ON	smai.shkrm_id = dt.shkrm_id   
		      			CROSS JOIN	@imprest_out i
		      ) s
				ON t.shkrm_id = s.shkrm_id
		WHEN MATCHED THEN 
		     UPDATE	
		     SET 	doc_id                  = s.doc_id,
		     		doc_type_id             = s.doc_type_id,
		     		rmt_id                  = s.rmt_id,
		     		art_id                  = s.art_id,
		     		color_id                = s.color_id,
		     		su_id                   = s.su_id,
		     		suppliercontract_id     = s.suppliercontract_id,
		     		okei_id                 = s.okei_id,
		     		qty                     = s.qty,
		     		stor_unit_residues_okei_id = s.stor_unit_residues_okei_id,
		     		stor_unit_residues_qty = s.stor_unit_residues_qty,
		     		nds                     = s.nds,
		     		dt                      = @dt,
		     		employee_id             = @employee_id,
		     		frame_width             = s.frame_width,
		     		is_defected             = s.is_defected,
		     		amount                  = NULL
		WHEN NOT MATCHED BY TARGET THEN 
		     INSERT
		     	(
		     		imprest_id,
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
		     		frame_width,
		     		is_defected,
		     		amount
		     	)
		     VALUES
		     	(
		     		s.imprest_id,
		     		s.shkrm_id,
		     		s.doc_id,
		     		s.doc_type_id,
		     		s.rmt_id,
		     		s.art_id,
		     		s.color_id,
		     		s.su_id,
		     		s.suppliercontract_id,
		     		s.okei_id,
		     		s.qty,
		     		s.stor_unit_residues_okei_id,
		     		s.stor_unit_residues_qty,
		     		s.nds,
		     		@dt,
		     		@employee_id,
		     		s.frame_width,
		     		s.is_defected,
		     		NULL
		     	)
		WHEN NOT MATCHED BY SOURCE THEN 
		     DELETE	;
		
		WITH cte_target AS (
			SELECT	is1.is_id,
					is1.imprest_id,
					is1.sample_id,
					is1.shkrm_sample_amount,
					is1.other_amount,
					is1.comment,
					is1.dt,
					is1.employee_id
			FROM	Warehouse.ImprestSample is1   
					INNER JOIN	@imprest_out i
						ON	i.imprest_id = is1.imprest_id
		)
		MERGE cte_target t
		USING (
		      	SELECT	st.sample_id,
		      			st.comment,
		      			st.other_amount,
		      			i.imprest_id
		      	FROM	@sample_tab st   
		      			CROSS JOIN	@imprest_out i
		      ) s
				ON t.sample_id = s.sample_id
		WHEN MATCHED THEN 
		     UPDATE	
		     SET 	other_amount     = s.other_amount,
		     		comment          = s.comment,
		     		dt               = @dt,
		     		employee_id      = @employee_id
		WHEN NOT MATCHED BY TARGET THEN 
		     INSERT
		     	(
		     		imprest_id,
		     		sample_id,
		     		shkrm_sample_amount,
		     		other_amount,
		     		comment,
		     		dt,
		     		employee_id
		     	)
		     VALUES
		     	(
		     		s.imprest_id,
		     		s.sample_id,
		     		NULL,
		     		s.other_amount,
		     		s.comment,
		     		@dt,
		     		@employee_id
		     	)
		WHEN NOT MATCHED BY SOURCE THEN 
		     DELETE	;
		
		WITH cte_target AS (
			SELECT	iod.iod_id,
					iod.imprest_id,
					iod.iod_num,
					iod.iod_descr,
					iod.iod_amount,
					iod.dt,
					iod.employee_id
			FROM	Warehouse.ImprestOtherDetail iod   
					INNER JOIN	@imprest_out i
						ON	i.imprest_id = iod.imprest_id
		)
		MERGE cte_target t
		USING (
		      	SELECT	ot.iod_num,
		      			ot.descr,
		      			ot.amount,
		      			i.imprest_id
		      	FROM	@other_tab ot   
		      			CROSS JOIN	@imprest_out i
		      ) s
				ON t.iod_num = s.iod_num
		WHEN MATCHED THEN 
		     UPDATE	
		     SET 	iod_descr       = s.descr,
		     		iod_amount      = s.amount,
		     		dt              = @dt,
		     		employee_id     = @employee_id
		WHEN NOT MATCHED BY TARGET THEN 
		     INSERT
		     	(
		     		imprest_id,
		     		iod_num,
		     		iod_descr,
		     		iod_amount,
		     		dt,
		     		employee_id
		     	)
		     VALUES
		     	(
		     		s.imprest_id,
		     		s.iod_num,
		     		s.descr,
		     		s.amount,
		     		@dt,
		     		@employee_id
		     	)
		WHEN NOT MATCHED BY SOURCE THEN 
		     DELETE	;
		     
		UPDATE	s
		SET 	state_id        = @shkrm_state_dst,
				dt              = @dt,
				employee_id     = @employee_id
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
				INNER JOIN	@shkrm_tab dt
					ON	dt.shkrm_id = s.shkrm_id
		WHERE s.state_id != @shkrm_state_dst
		
		COMMIT TRANSACTION
		
		SELECT	iou.imprest_id
		FROM	@imprest_out iou
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