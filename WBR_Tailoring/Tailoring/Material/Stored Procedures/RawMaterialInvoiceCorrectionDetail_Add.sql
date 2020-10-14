CREATE PROCEDURE [Material].[RawMaterialInvoiceCorrectionDetail_Add]
	@shkrm_id INT,
	@rmic_id INT,
	@employee_id INT
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @dt DATETIME2(0) = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	DECLARE @rmict_id TINYINT
	DECLARE @with_log BIT = 1
	DECLARE @shkrm_state_dst INT = 16
	DECLARE @proc_id INT
	EXECUTE @proc_id = History.ProcId_GetByName @procid = @@PROCID
	DECLARE @out TABLE (rmid_id INT)
	
	
	DECLARE @rmt_id INT
	DECLARE @art_id INT
	DECLARE @okei_id INT
	DECLARE @qty DECIMAL(9, 3)
	DECLARE @stor_unit_residues_okei_id INT
	DECLARE @stor_unit_residues_qty DECIMAL(9, 3)	        
	DECLARE @doc_id INT	        
	DECLARE @doc_type_id TINYINT = 1
	DECLARE @rmid_id INT
	DECLARE @color_id INT
	DECLARE @suppliercontract_id INT
	DECLARE @su_id INT
	DECLARE @shksu_id INT
	DECLARE @frame_width SMALLINT
	DECLARE @is_defected BIT
	DECLARE @nds TINYINT
	DECLARE @amount DECIMAL(19, 8)
	
	SELECT	@error_text = CASE 
	      	                   WHEN rmic.rmic_id IS NULL THEN 'Документа возврата с номером ' + CAST(v.rmic_id AS VARCHAR(10)) + ' не существует'
	      	                   WHEN rmic.close_dt IS NOT NULL THEN 'Документ закрыт'
	      	                   ELSE NULL
	      	              END,
			@rmict_id     = rmic.rmict_id,
			@doc_id       = rmi.doc_id
	FROM	(VALUES(@rmic_id))v(rmic_id)   
			LEFT JOIN	Material.RawMaterialInvoiceCorrection rmic   
			INNER JOIN	Material.RawMaterialInvoice rmi
				ON	rmi.rmi_id = rmic.rmi_id
				ON	rmic.rmic_id = v.rmic_id
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	SELECT	@error_text = CASE 
	      	                   WHEN sm.shkrm_id IS NULL THEN 'Штрихкода ' + CAST(v.shkrm_id AS VARCHAR(10)) + ' не существует.'
	      	                   WHEN smai.shkrm_id IS NULL THEN 'Штрихкод ' + CAST(v.shkrm_id AS VARCHAR(10)) +
	      	                        ' не описан.'
	      	                   WHEN sms.shkrm_id IS NULL THEN 'У штрихкода ' + CAST(v.shkrm_id AS VARCHAR(10)) +
	      	                        ' нет статуса, операции со штрихкодом запрещены. Обратитесь к руководителю'
	      	                   WHEN sms.state_id = @shkrm_state_dst THEN 'Штрихкод уже подготовлен для возврата поставщику'
	      	                   WHEN smsg.state_src_id IS NULL THEN 'Штрихкод ' + CAST(v.shkrm_id AS VARCHAR(10)) + ' в статусе ' + smsd.state_name +
	      	                        '. Переход в статус ' + smsd2.state_name + ' запрещен.'
	      	                   WHEN smai.doc_type_id != @doc_type_id THEN 'Не верный тип документа.'
	      	                   WHEN rmr.shkrm_id IS NOT NULL THEN 'Штрихкода ' + CAST(v.shkrm_id AS VARCHAR(10)) +
	      	                        ' уже в документе возврата без корректировки СФ.'
	      	                   WHEN rmicd.shkrm_id IS NOT NULL THEN 'Штрихкода ' + CAST(v.shkrm_id AS VARCHAR(10)) +
	      	                        ' уже в документе возврата c корректировкой СФ.'
	      	                   WHEN @rmict_id = 2 AND rmtsm.rmt_id IS NULL THEN 
	      	                        'В выбранный документ можно запикивать только основные средства. Данный ШК описан не как ОС. Обратитесь к руководителю'
	      	                   WHEN sma.shkrm_id IS NULL THEN 'Штрихкод ' + CAST(v.shkrm_id AS VARCHAR(10)) + ' без цены.'
	      	                   WHEN sma.amount = 0 THEN 'Штрихкод ' + CAST(v.shkrm_id AS VARCHAR(10)) + ' с 0 стоимостью.'
	      	                   WHEN sma.final_dt IS NULL THEN 'Штрихкод ' + CAST(v.shkrm_id AS VARCHAR(10)) + ' с не закрытым распределением стоимости.'
	      	                   WHEN smai.doc_type_id = @doc_type_id AND smai.doc_id != @doc_id THEN 'Штрихкод ' + CAST(v.shkrm_id AS VARCHAR(10)) +
	      	                        ' должен быть из поступления № ' + CAST(@doc_id AS VARCHAR(10)) + ' а этот из ' + CAST(smai.doc_id AS VARCHAR(10))
	      	                   ELSE NULL
	      	              END,
			@rmt_id = smai.rmt_id,
			@art_id = smai.art_id,
			@okei_id = smai.okei_id,
			@qty = smai.qty,
			@stor_unit_residues_okei_id = smai.stor_unit_residues_okei_id,
			@stor_unit_residues_qty = smai.stor_unit_residues_qty,
			@color_id = smai.color_id,
			@su_id = smai.su_id,
			@frame_width = smai.frame_width,
			@is_defected = smai.is_defected,
			@nds = smai.nds,
			@rmid_id = rmid.rmid_id,
			@shksu_id = rmid.shksu_id,
			@suppliercontract_id = rmid.suppliercontract_id,
			@amount = sma.amount
	FROM	(VALUES(@shkrm_id))v(shkrm_id)   
			LEFT JOIN	Warehouse.SHKRawMaterial sm   
			LEFT JOIN	Warehouse.SHKRawMaterialState sms   
			INNER JOIN	Warehouse.SHKRawMaterialStateDict smsd
				ON	smsd.state_id = sms.state_id
				ON	sms.shkrm_id = sm.shkrm_id   
			LEFT JOIN	Warehouse.SHKRawMaterialStateGraph smsg
				ON	sms.state_id = smsg.state_src_id
				AND	smsg.state_dst_id = @shkrm_state_dst
				ON	sm.shkrm_id = v.shkrm_id   
			LEFT  JOIN	Warehouse.SHKRawMaterialStateDict smsd2
				ON	smsd2.state_id = @shkrm_state_dst   
			LEFT JOIN	Warehouse.SHKRawMaterialActualInfo smai
				ON	smai.shkrm_id = v.shkrm_id   
			LEFT JOIN	Material.RawMaterialIncomeDetail rmid
				ON	rmid.doc_id = smai.doc_id
				AND	rmid.doc_type_id = smai.doc_type_id
				AND	rmid.shkrm_id = sm.shkrm_id   
			LEFT JOIN	Material.RawMaterialReturn rmr
				ON	rmr.shkrm_id = sm.shkrm_id   
			LEFT JOIN	Material.RawMaterialInvoiceCorrectionDetail rmicd
				ON	rmicd.shkrm_id = sm.shkrm_id   
			LEFT JOIN	Material.RawMaterialTypeStuffModel rmtsm
				ON	smai.rmt_id = rmtsm.rmt_id   
			LEFT JOIN	Warehouse.SHKRawMaterialAmount sma
				ON	sma.shkrm_id = sm.shkrm_id
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	BEGIN TRY
		BEGIN TRANSACTION	
		
		INSERT INTO Material.RawMaterialInvoiceCorrectionDetail
			(
				rmic_id,
				return_dt,
				return_employee_id,
				rmid_id,
				shkrm_id,
				rmt_id,
				art_id,
				color_id,
				suppliercontract_id,
				su_id,
				okei_id,
				qty,
				stor_unit_residues_okei_id,
				stor_unit_residues_qty,
				shksu_id,
				frame_width,
				is_defected,
				nds,
				dt,
				employee_id,
				amount
			)OUTPUT	INSERTED.rmid_id
			 INTO	@out (
			 		rmid_id
			 	)
		VALUES
			(
				@rmic_id,
				NULL,
				NULL,
				@rmid_id,
				@shkrm_id,
				@rmt_id,
				@art_id,
				@color_id,
				@suppliercontract_id,
				@su_id,
				@okei_id,
				@qty,
				@stor_unit_residues_okei_id,
				@stor_unit_residues_qty,
				@shksu_id,
				@frame_width,
				@is_defected,
				@nds,
				@dt,
				@employee_id,
				@amount
			)
		
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
				INNER JOIN	Warehouse.SHKRawMaterialStateGraph smsg
					ON	s.state_id = smsg.state_src_id
					AND	smsg.state_dst_id = @shkrm_state_dst
		WHERE	shkrm_id = @shkrm_id
		
		IF @@ROWCOUNT = 0
		BEGIN
		    SET @with_log = 0
		    RAISERROR('Операция со штрихкодом %d запрещена', 16, 1, @shkrm_id);
		    RETURN
		END
		
		UPDATE	Material.RawMaterialInvoiceCorrection
		SET 	amount_shk     = amount_shk + @amount
		WHERE	rmic_id        = @rmic_id
		
		COMMIT TRANSACTION
		
		SELECT	ot.rmid_id,
				@shkrm_id                   shkrm_id,
				@frame_width                frame_width,
				@rmt_id                     rmt_id,
				rmt.rmt_name,
				@art_id                     art_id,
				a.art_name,
				@color_id                   color_id,
				cc.color_name,
				@su_id                      su_id,
				su.su_name,
				@okei_id                    okei_id,
				o.fullname                  okei_name,
				@qty                        qty,
				@stor_unit_residues_okei_id stor_unit_residues_okei_id,
				@stor_unit_residues_qty     stor_unit_residues_qty,
				CASE 
				     WHEN @stor_unit_residues_qty = 0 THEN 0
				     ELSE @amount / @stor_unit_residues_qty
				END                         price,
				@amount                     amount,
				@nds                        nds,
				CAST(@dt AS DATETIME)       dt,
				@employee_id                employee_id,
				@shksu_id                   shksu_id,
				@is_defected                is_defected
		FROM	@out ot   
				INNER JOIN	Material.RawMaterialType rmt
					ON	rmt.rmt_id = @rmt_id   
				INNER JOIN	RefBook.SpaceUnit su
					ON	su.su_id = @su_id   
				INNER JOIN	Material.ClothColor cc
					ON	cc.color_id = @color_id   
				INNER JOIN	Material.Article a
					ON	a.art_id = @art_id   
				INNER JOIN	Qualifiers.OKEI o
					ON	o.okei_id = @okei_id
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
		
		IF @with_log = 1
		BEGIN
		    RAISERROR('Ошибка %d в строке %d  %s', @esev, @estate, @ErrNum, @Line, @Mess) WITH LOG;
		END
		ELSE
		BEGIN
		    RAISERROR('Ошибка %d в строке %d  %s', @esev, @estate, @ErrNum, @Line, @Mess)
		END
	END CATCH 