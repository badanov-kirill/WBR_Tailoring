CREATE PROCEDURE [Material].[RawMaterialIncome_ShkAdd]
	@shksu_id INT,
	@shkrm_id INT,
	@rmt_id INT,
	@art_name VARCHAR(12),
	@color_id INT,
	@su_id INT,
	@okei_id INT,
	@qty DECIMAL(9, 2),
	@stor_unit_residues_okei_id INT,
	@stor_unit_residues_qty DECIMAL(9, 2),
	@nds TINYINT,
	@employee_id INT,
	@frame_width SMALLINT = NULL,
	@is_defected BIT = 0,
	@defected_descr VARCHAR(900) = NULL,
	@gross_mass INT,
	@tissue_density SMALLINT = NULL,
	@stuff_shk_id INT = NULL,
	@manufactured_number VARCHAR(20) = NULL,
	@logic_state_id INT = NULL
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @dt dbo.SECONDSTIME = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	DECLARE @doc_type_id TINYINT = 1
	DECLARE @art_id INT
	DECLARE @shk_state INT = 1
	DECLARE @proc_id INT
	DECLARE @amount DECIMAL(19, 8) = 0
	DECLARE @doc_id INT
	DECLARE @suppliercontract_id INT
	DECLARE @supplier_name VARCHAR(100)
	DECLARE @rmi_status_unload TINYINT = 3 --Разгрузка
	DECLARE @rmi_status_accept TINYINT = 4 -- Приемка
	DECLARE @rmi_status_allow_accept TINYINT = 2 -- Разрешена приемка
	DECLARE @stuff_model_id INT
	DECLARE @rmtv_out TABLE (rmtv_id INT)
	DECLARE @fabricator_id INT
	DECLARE @fabricator_name VARCHAR(100)
	
	IF @stor_unit_residues_qty <= 0
	   OR @qty <= 0
	BEGIN
	    RAISERROR('Количество должно быть положительным', 16, 1)
	    RETURN
	END
	
	EXECUTE @proc_id = History.ProcId_GetByName @procid = @@PROCID
	
	SELECT	@error_text = CASE 
	      	                   WHEN su.shksu_id IS NULL THEN 'Штрихкода грузового места с кодом ' + CAST(v.shksu_id AS VARCHAR(10)) + ' не существует.'
	      	                   WHEN su.doc_id IS NULL THEN 'Штрихкод грузового места с кодом ' + CAST(v.shksu_id AS VARCHAR(10)) + ' не привязан к документу.'
	      	                   WHEN su.close_dt IS NOT NULL THEN 'Грузовое место закрыто, использовать нельзя.'
	      	                   WHEN rmi.rmis_id NOT IN (@rmi_status_unload, @rmi_status_accept, @rmi_status_allow_accept) THEN 'Документ находится в статусе ' +
	      	                        rmis.rmis_name + ' принимать материалы по нему нельзя'
	      	                   ELSE NULL
	      	              END,
			@doc_id                  = su.doc_id,
			@suppliercontract_id     = rmi.suppliercontract_id,
			@supplier_name           = s.supplier_name,
			@fabricator_id			 = rmi.fabricator_id,
			@fabricator_name		 = f.fabricator_name	
	FROM	(VALUES(@shksu_id))v(shksu_id)   
			LEFT JOIN	Warehouse.SHKSpaceUnit su   
			INNER JOIN	Material.RawMaterialIncome rmi   
			INNER JOIN	Suppliers.Supplier s
				ON	s.supplier_id = rmi.supplier_id
				ON	rmi.doc_id = su.doc_id
				AND	rmi.doc_type_id = su.doc_type_id   
			INNER JOIN	Material.RawMaterialIncomeStatus rmis
				ON	rmis.rmis_id = rmi.rmis_id
				ON	su.shksu_id = v.shksu_id
			LEFT JOIN Settings.Fabricators f 
				ON f.fabricator_id = rmi.fabricator_id
					
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END

	IF @fabricator_name IS  NULL
	BEGIN
	    RAISERROR('%s', 16, 1, 'Изготовитель не определен.')
	    RETURN
	END
	
	SELECT	@error_text = CASE 
	      	                   WHEN sm.shkrm_id IS NULL THEN 'Не корректный штрихкод материала'
	      	                   WHEN smai.shkrm_id IS NOT NULL THEN 'Штрихкод ' + CAST(smai.shkrm_id AS VARCHAR(10)) + ' уже оприходован на склад документом ' +
	      	                        dt.doc_type_name + ' № ' + CAST(smai.doc_id AS VARCHAR(10)) + ' датой ' + CONVERT(VARCHAR(20), smai.dt, 121)
	      	                   WHEN sms.shkrm_id IS NOT NULL THEN 'Штрихкод ' + CAST(sms.shkrm_id AS VARCHAR(10)) + ' уже находится в статусе ' + smsd.state_name 
	      	                        + ', использовать для приемки нельзя.'
	      	                   WHEN sm.dt_mapping IS NOT NULL THEN 'Нельзя использовать шк ' + CAST(sms.shkrm_id AS VARCHAR(10)) + ' повторно'
	      	                   ELSE NULL
	      	              END
	FROM	(VALUES(@shkrm_id))v(shkrm_id)   
			LEFT JOIN	Warehouse.SHKRawMaterial sm
				ON	sm.shkrm_id = v.shkrm_id   
			LEFT JOIN	Warehouse.SHKRawMaterialActualInfo smai   
			INNER JOIN	Documents.DocumentType dt
				ON	dt.doc_type_id = smai.doc_type_id
				ON	smai.shkrm_id = sm.shkrm_id   
			LEFT JOIN	Warehouse.SHKRawMaterialState sms   
			INNER JOIN	Warehouse.SHKRawMaterialStateDict smsd
				ON	smsd.state_id = sms.state_id
				ON	sms.shkrm_id = sm.shkrm_id
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	SELECT	@error_text = CASE 
	      	                   WHEN rmt.rmt_id IS NULL THEN 'Типа материала с кодом ' + CAST(v.rmt_id AS VARCHAR(10)) + ' не существует.'
	      	                   WHEN rmt.stor_unit_residues_okei_id != @stor_unit_residues_okei_id THEN 
	      	                        'Для типа материала не совпадает использованная еденица хранения остатков, перечитайте данные, и заполните остаток по новому'
	      	                   WHEN rmtsm.stuff_model_id IS NOT NULL AND ISNULL(@stuff_shk_id, 0) = 0 THEN 'Выбранный тип, является основным средством, необходимо указать ШК основного средства'
	      	                   WHEN rmtsm.stuff_model_id IS NOT NULL AND ISNULL(@manufactured_number, '') = '' THEN 'Выбранный тип, является основным средством, необходимо указать серийный номер'
	      	                   ELSE NULL
	      	              END,
	      	              @stuff_model_id = rmtsm.stuff_model_id
	FROM	(VALUES(@rmt_id))v(rmt_id)   
			LEFT JOIN	Material.RawMaterialType rmt
				ON	v.rmt_id = rmt.rmt_id
			LEFT JOIN Material.RawMaterialTypeStuffModel rmtsm
				ON rmtsm.rmt_id = rmt.rmt_id
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	IF (@stuff_shk_id IS NOT NULL OR @manufactured_number IS NOT NULL) AND @stuff_model_id IS NULL
	BEGIN
		RAISERROR('Для выбранного типа, не указан код основного средства, обратитесь к руководителю', 16, 1)
	    RETURN
	END	
	
	IF NOT EXISTS(
	   	SELECT	1
	   	FROM	Material.ClothColor cc
	   	WHERE cc.color_id = @color_id
	   )
	BEGIN
	    RAISERROR('Цвета с кодом %d не существует', 16, 1, @color_id)
	    RETURN
	END
	
	
	IF NOT EXISTS (
	   	SELECT	1
	   	FROM	RefBook.SpaceUnit su
	   	WHERE	su.su_id = @su_id
	   )
	BEGIN
	    RAISERROR('Грузового места с кодом %d не существует', 16, 1, @su_id)
	    RETURN
	END
	
	IF NOT EXISTS (
	   	SELECT	1
	   	FROM	Qualifiers.OKEI o
	   	WHERE	o.okei_id = @okei_id
	   )
	BEGIN
	    RAISERROR('Еденицы измерения с кодом %d не существует', 16, 1, @okei_id)
	    RETURN
	END
	
	SELECT	@error_text = CASE 
	      	                   WHEN n.nds IS NULL THEN 'НДС ' + CAST(v.nds AS VARCHAR(5)) + ' отсутствует в справочнике'
	      	                   WHEN n.is_deleted = 1 THEN 'НДС ' + CAST(v.nds AS VARCHAR(5)) + ' запрещено использовать'
	      	                   ELSE NULL
	      	              END
	FROM	(VALUES(@nds))v(nds)   
			LEFT JOIN	RefBook.NDS n
				ON	n.nds = v.nds
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	IF @is_defected = 1
	   AND @defected_descr IS NULL
	BEGIN
	    RAISERROR('Не указано описание брака', 16, 1)
	    RETURN
	END
	
	INSERT INTO Material.Article
	  (
	    art_name
	  )
	SELECT	@art_name
	WHERE	NOT EXISTS (
	     		SELECT	1
	     		FROM	Material.Article a
	     		WHERE	a.art_name = @art_name
	     	)
	
	IF @@ROWCOUNT > 0
	BEGIN
	    SET @art_id = SCOPE_IDENTITY()
	END
	ELSE
	BEGIN
	    SELECT	@art_id = a.art_id
	    FROM	Material.Article a
	    WHERE	a.art_name = @art_name
	END
	
	IF @logic_state_id IS NOT NULL
	   AND NOT EXISTS (
	       	SELECT	1
	       	FROM	Warehouse.SHKRawMaterialLogicStateDict smlsd
	       	WHERE	smlsd.state_id = @logic_state_id
	       )
	BEGIN
	    RAISERROR('Логического статуса с кодом %d не существует', 16, 1, @logic_state_id)
	    RETURN
	END
	
	BEGIN TRY
		BEGIN TRANSACTION 
		
		INSERT INTO Material.RawMaterialIncomeDetail
		  (
		    doc_id,
		    doc_type_id,
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
		    amount,
		    nds,
		    dt,
		    employee_id,
		    is_deleted,
		    shksu_id,
		    frame_width,
		    is_defected
		  )OUTPUT	INSERTED.rmid_id,
		   		INSERTED.doc_id,
		   		INSERTED.doc_type_id,
		   		INSERTED.shkrm_id,
		   		INSERTED.rmt_id,
		   		INSERTED.art_id,
		   		INSERTED.color_id,
		   		INSERTED.suppliercontract_id,
		   		INSERTED.su_id,
		   		INSERTED.okei_id,
		   		INSERTED.qty,
		   		INSERTED.stor_unit_residues_okei_id,
		   		INSERTED.stor_unit_residues_qty,
		   		INSERTED.amount,
		   		INSERTED.nds,
		   		INSERTED.dt,
		   		INSERTED.employee_id,
		   		INSERTED.is_deleted,
		   		INSERTED.shksu_id,
		   		INSERTED.frame_width
		   INTO	History.RawMaterialIncomeDetail (
		   		rmid_id,
		   		doc_id,
		   		doc_type_id,
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
		   		amount,
		   		nds,
		   		dt,
		   		employee_id,
		   		is_deleted,
		   		shksu_id,
		   		frame_width
		   	)
		VALUES
		  (
		    @doc_id,
		    @doc_type_id,
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
		    @amount,
		    @nds,
		    @dt,
		    @employee_id,
		    0,
		    @shksu_id,
		    @frame_width,
		    @is_defected
		  )
		
		UPDATE	Warehouse.SHKRawMaterial
		SET 	dt_mapping     = @dt
		WHERE	shkrm_id       = @shkrm_id AND dt_mapping IS NULL
		
		IF @@ROWCOUNT = 0
		BEGIN
			RAISERROR('Нельзя использовать шк %d повторно',16,1,@shkrm_id)
			RETURN
		END
		
		INSERT INTO Warehouse.SHKRawMaterialActualInfo
		  (
		    shkrm_id,
		    doc_id,
		    doc_type_id,
		    suppliercontract_id,
		    rmt_id,
		    art_id,
		    color_id,
		    su_id,
		    okei_id,
		    qty,
		    stor_unit_residues_okei_id,
		    stor_unit_residues_qty,
		    dt,
		    employee_id,
		    frame_width,
		    is_defected,
		    is_deleted,
		    nds,
		    gross_mass,
		    tissue_density,
			fabricator_id
		  )OUTPUT	INSERTED.shkrm_id,
		   		INSERTED.doc_id,
		   		INSERTED.doc_type_id,
		   		INSERTED.suppliercontract_id,
		   		INSERTED.rmt_id,
		   		INSERTED.art_id,
		   		INSERTED.color_id,
		   		INSERTED.su_id,
		   		INSERTED.okei_id,
		   		INSERTED.qty,
		   		INSERTED.stor_unit_residues_okei_id,
		   		INSERTED.stor_unit_residues_qty,
		   		INSERTED.dt,
		   		INSERTED.employee_id,
		   		INSERTED.frame_width,
		   		INSERTED.is_defected,
		   		INSERTED.is_deleted,
		   		@proc_id,
		   		INSERTED.nds,
		   		INSERTED.gross_mass,
		   		INSERTED.is_terminal_residues,
		   		INSERTED.tissue_density,
				@fabricator_id
		   INTO	History.SHKRawMaterialActualInfo (
		   		shkrm_id,
		   		doc_id,
		   		doc_type_id,
		   		suppliercontract_id,
		   		rmt_id,
		   		art_id,
		   		color_id,
		   		su_id,
		   		okei_id,
		   		qty,
		   		stor_unit_residues_okei_id,
		   		stor_unit_residues_qty,
		   		dt,
		   		employee_id,
		   		frame_width,
		   		is_defected,
		   		is_deleted,
		   		proc_id,
		   		nds,
		   		gross_mass,
		   		is_terminal_residues,
		   		tissue_density,
				fabricator_id
		   	)
		VALUES
		  (
		    @shkrm_id,
		    @doc_id,
		    @doc_type_id,
		    @suppliercontract_id,
		    @rmt_id,
		    @art_id,
		    @color_id,
		    @su_id,
		    @okei_id,
		    @qty,
		    @stor_unit_residues_okei_id,
		    @stor_unit_residues_qty,
		    @dt,
		    @employee_id,
		    @frame_width,
		    @is_defected,
		    0,
		    @nds,
		    @gross_mass,
		    @tissue_density,
			@fabricator_id
		  )
		
		INSERT INTO Warehouse.SHKRawMaterialInfo
		  (
		    shkrm_id,
		    doc_id,
		    doc_type_id,
		    suppliercontract_id,
		    rmt_id,
		    art_id,
		    color_id,
		    su_id,
		    frame_width,
		    nds,
		    tissue_density
		  )OUTPUT	INSERTED.shkrm_id,
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
		VALUES
		  (
		    @shkrm_id,
		    @doc_id,
		    @doc_type_id,
		    @suppliercontract_id,
		    @rmt_id,
		    @art_id,
		    @color_id,
		    @su_id,
		    @frame_width,
		    @nds,
		    @tissue_density
		  )
		  
		  INSERT INTO Warehouse.SHKRawMaterialAmount
		  (
		    shkrm_id,
		    stor_unit_residues_okei_id,
		    stor_unit_residues_qty,
		    amount,
		    gross_mass
		  )OUTPUT	INSERTED.shkrm_id,		   		
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
		VALUES
		  (
		    @shkrm_id,
		    @stor_unit_residues_okei_id,
		    @stor_unit_residues_qty,
		    @amount,
		    @gross_mass
		  )
		
		IF @is_defected = 1
		BEGIN
		    INSERT INTO Warehouse.SHKRawMaterialDefectDescr
		      (
		        shkrm_id,
		        descr,
		        dt,
		        employee_id,
		        okei_id,
		        qty
		      )OUTPUT	INSERTED.shkrm_id,
		       		INSERTED.descr,
		       		INSERTED.dt,
		       		INSERTED.employee_id,
		       		@proc_id
		       INTO	History.SHKRawMaterialDefectDescr (
		       		shkrm_id,
		       		descr,
		       		dt,
		       		employee_id,
		       		proc_id
		       	)
		    VALUES
		      (
		        @shkrm_id,
		        @defected_descr,
		        @dt,
		        @employee_id,
		        @okei_id,
		        @qty
		      )
		END
		
		INSERT INTO Warehouse.SHKRawMaterialState
		  (
		    shkrm_id,
		    state_id,
		    dt,
		    employee_id
		  )OUTPUT	INSERTED.shkrm_id,
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
		VALUES
		  (
		    @shkrm_id,
		    @shk_state,
		    @dt,
		    @employee_id
		  )
		
		UPDATE	Material.RawMaterialIncome
		SET 	rmis_id = @rmi_status_accept,
				goods_dt = @dt,
				dt = @dt,
				employee_id = @employee_id
				OUTPUT	INSERTED.doc_id,
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
						INSERTED.fabricator_id
				INTO	History.RawMaterialIncome (
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
						fabricator_id
					)
		WHERE	doc_id = @doc_id
				AND	doc_type_id = @doc_type_id
				AND	rmis_id = @rmi_status_unload
				
		IF @stuff_model_id IS NOT NULL
		BEGIN
			INSERT INTO Warehouse.ShkRawMaterial_StuffModel
			(
				shkrm_id,
				stuff_shk_id,
				stuff_model_id,
				manufactured_number,
				dt,
				employee_id
			)
			VALUES
			(
				@shkrm_id,
				@stuff_shk_id,
				@stuff_model_id,
				@manufactured_number,
				@dt,
				@employee_id
			)
		END
		
		INSERT INTO Material.RawMaterialTypeVariant
			(
				rmt_id,
				art_id,
				frame_width,
				rmt_astra_id
			)OUTPUT	INSERTED.rmtv_id
			 INTO	@rmtv_out (
			 		rmtv_id
			 	)
		SELECT	@rmt_id,
				@art_id,
				@frame_width,
				NULL
		WHERE	NOT EXISTS (
		     		SELECT	1
		     		FROM	Material.RawMaterialTypeVariant rmtv
		     		WHERE	rmtv.rmt_id = @rmt_id
		     				AND	rmtv.art_id = @art_id
		     				AND	(rmtv.frame_width = @frame_width OR (rmtv.frame_width IS NULL AND @frame_width IS NULL))
		     	)
		
		INSERT INTO SyncFinance.RawMaterialTypeVariantUpload
			(
				rmtv_id,
				dt,
				employee_id
			)
		SELECT	rmtv_id,
				@dt,
				@employee_id
		FROM	@rmtv_out
		
		IF @logic_state_id IS NOT NULL
		BEGIN
			INSERT INTO Warehouse.SHKRawMaterialLogicState
			(
				shkrm_id,
				state_id,
				dt,
				employee_id
			)
			VALUES
			(
				@shkrm_id,
				@logic_state_id,
				@dt,
				@employee_id
			)
		END
		
		COMMIT TRANSACTION
		
		SELECT	@shkrm_id          shkrm_id,
				@supplier_name     supplier_name,
				@fabricator_id	   fabricator_id,		
				@fabricator_name   fabricator_name	
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
		--WITH LOG;
	END CATCH 