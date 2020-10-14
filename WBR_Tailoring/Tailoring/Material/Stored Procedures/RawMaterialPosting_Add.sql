CREATE PROCEDURE [Material].[RawMaterialPosting_Add]
	@rmt_id INT,
	@art_name VARCHAR(12),
	@color_id INT,
	@suppliercontract_id INT,
	@su_id INT,
	@okei_id INT,
	@qty DECIMAL(9, 2),
	@stor_unit_residues_okei_id INT,
	@stor_unit_residues_qty DECIMAL(9, 2),
	@amount DECIMAL(19, 8),
	@nds TINYINT,
	@employee_id INT,
	@frame_width SMALLINT = NULL,
	@is_defected BIT = 0,
	@defected_descr VARCHAR(900) = NULL,
	@gross_mass INT,
	@tissue_density SMALLINT = NULL
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @dt dbo.SECONDSTIME = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	DECLARE @shkrm_id INT
	DECLARE @doc_id INT
	DECLARE @doc_type_id TINYINT = 2
	DECLARE @art_id INT
	DECLARE @shk_state INT = 2
	DECLARE @proc_id INT
	
	IF @stor_unit_residues_qty <= 0
	   OR @qty <= 0
	BEGIN
	    RAISERROR('Количество должно быть положительным', 16, 1)
	    RETURN
	END
	
	IF @amount < 0
	BEGIN
	    RAISERROR('Сумма должна быть положительной', 16, 1)
	    RETURN
	END
	
	EXECUTE @proc_id = History.ProcId_GetByName @procid = @@PROCID
	
	SELECT	@error_text = CASE 
	      	                   WHEN COUNT(rmpb.shkrm_id) = 0 THEN 'Не запикан штрихкод материала для оприходования'
	      	                   WHEN COUNT(rmpb.shkrm_id) > 1 THEN 'В очереди более одного шк, обратитесь к разработчику'
	      	                   WHEN DATEDIFF(minute, MAX(rmpb.dt), @dt) > 60 THEN 'Материал запикан более часа назад. Запикайте материал снова'
	      	                   ELSE NULL
	      	              END,
			@shkrm_id = MAX(rmpb.shkrm_id)
	FROM	Material.RawMaterialPostingBuffer rmpb
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	SELECT	@error_text = 'Штрихкод ' + CAST(smai.shkrm_id AS VARCHAR(10)) + ' уже оприходован на склад документом ' +
	      	dt.doc_type_name + ' № ' + CAST(smai.doc_id AS VARCHAR(10)) + ' датой ' + CONVERT(VARCHAR(20), smai.dt, 121)
	FROM	Warehouse.SHKRawMaterialActualInfo smai   
			INNER JOIN	Documents.DocumentType dt
				ON	dt.doc_type_id = smai.doc_type_id
	WHERE	smai.shkrm_id = @shkrm_id
	
	IF @error_text IS NOT NULL
	BEGIN
	    DELETE	
	    FROM	Material.RawMaterialPostingBuffer
	    WHERE	shkrm_id = @shkrm_id
	    
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	SELECT	@error_text = 'Штрихкод ' + CAST(sms.shkrm_id AS VARCHAR(10)) + ' уже находится в статусе ' + smsd.state_name + ', оприходовать нельзя.'
	FROM	Warehouse.SHKRawMaterialState sms   
			INNER JOIN	Warehouse.SHKRawMaterialStateDict smsd
				ON	smsd.state_id = sms.state_id
	WHERE	sms.shkrm_id = @shkrm_id
	
	IF @error_text IS NOT NULL
	BEGIN
	    DELETE	
	    FROM	Material.RawMaterialPostingBuffer
	    WHERE	shkrm_id = @shkrm_id
	    
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	SELECT	@error_text = CASE 
	      	                   WHEN rmt.rmt_id IS NULL THEN 'Типа материала с кодом ' + CAST(v.rmt_id AS VARCHAR(10)) + ' не существует.'
	      	                   WHEN rmt.stor_unit_residues_okei_id != @stor_unit_residues_okei_id THEN 
	      	                        'Для типа материала не совпадает использованная еденица хранения остатков, перечитайте данные, и заполните остаток по новому'
	      	                   ELSE NULL
	      	              END
	FROM	(VALUES(@rmt_id))v(rmt_id)   
			LEFT JOIN	Material.RawMaterialType rmt
				ON	v.rmt_id = rmt.rmt_id
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	IF EXISTS(
	   	SELECT	1
	   	FROM	Warehouse.SHKRawMaterial sm
	   	WHERE	sm.shkrm_id = @shkrm_id
	   			AND	sm.dt_mapping IS NOT NULL
	   )
	BEGIN
	    RAISERROR('Нельзя использовать шк %d повторно', 16, 1, @shkrm_id)
	    RETURN
	END
	
	IF NOT EXISTS(
	   	SELECT	1
	   	FROM	Material.ClothColor cc
	   )
	BEGIN
	    RAISERROR('Цвета с кодом %d не существует', 16, 1, @color_id)
	    RETURN
	END
	
	IF NOT EXISTS(
	   	SELECT	1
	   	FROM	Suppliers.SupplierContract sc
	   	WHERE	sc.suppliercontract_id = @suppliercontract_id
	   )
	BEGIN
	    RAISERROR('Договора поставщика с кодом %d не существует', 16, 1, @suppliercontract_id)
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
	
	BEGIN TRY
		BEGIN TRANSACTION 
		
		DELETE	
		FROM	Material.RawMaterialPostingBuffer
		WHERE	shkrm_id = @shkrm_id
		
		SET @doc_id = NEXT VALUE FOR Documents.RawMaterialPostingSeq
		
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
		
		INSERT INTO Material.RawMaterialPosting
		  (
		    doc_id,
		    doc_type_id,
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
		    shkrm_id
		  )OUTPUT	INSERTED.doc_id,
		   		INSERTED.doc_type_id,
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
		   		INSERTED.shkrm_id
		   INTO	History.RawMaterialPosting (
		   		doc_id,
		   		doc_type_id,
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
		   		shkrm_id
		   	)
		VALUES
		  (
		    @doc_id,
		    @doc_type_id,
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
		    @shkrm_id
		  )
		
		UPDATE	Warehouse.SHKRawMaterial
		SET 	dt_mapping = @dt
		WHERE	shkrm_id = @shkrm_id
				AND	dt_mapping IS NULL
		
		IF @@ROWCOUNT = 0
		BEGIN
		    RAISERROR('Нельзя использовать шк %d повторно', 16, 1, @shkrm_id)
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
		    tissue_density
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
		   		INSERTED.tissue_density
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
		    @tissue_density
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
		    gross_mass,
		    final_dt
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
		    @gross_mass,
		    @dt
		  )
		
		IF @is_defected = 1
		BEGIN
		    INSERT INTO Warehouse.SHKRawMaterialDefectDescr
		      (
		        shkrm_id,
		        descr,
		        dt,
		        employee_id
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
		        @employee_id
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
		
		COMMIT TRANSACTION
		
		SELECT	@shkrm_id shkrm_id
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