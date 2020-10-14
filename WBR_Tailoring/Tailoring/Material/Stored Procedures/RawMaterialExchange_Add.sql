CREATE PROCEDURE [Material].[RawMaterialExchange_Add]
	@shkrm_id INT,
	@need_rmt_id INT,
	@need_art_name VARCHAR(12),
	@need_color_id INT,
	@need_okei_id INT,
	@need_qty DECIMAL(9, 2),
	@employee_id INT
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @dt dbo.SECONDSTIME = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	DECLARE @proc_id INT
	DECLARE @shkrm_state_dst INT = 14
	DECLARE @need_art_id INT
	DECLARE @with_log BIT = 1
	DECLARE @amount DECIMAL(19, 8)
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
	
	IF ISNULL(@need_qty, 0) <= 0
	BEGIN
	    RAISERROR('Количество должно быть положительным', 16, 1)
	    RETURN
	END
	
	EXECUTE @proc_id = History.ProcId_GetByName @procid = @@PROCID
	
	SELECT	@error_text = CASE 
	      	                   WHEN rmt.rmt_id IS NULL THEN 'Типа материала с кодом ' + CAST(v.rmt_id AS VARCHAR(10)) + ' не существует.'
	      	                   WHEN rmt.stor_unit_residues_okei_id != @need_okei_id THEN 
	      	                        'Для типа материала не совпадает использованная еденица хранения остатков'
	      	                   ELSE NULL
	      	              END
	FROM	(VALUES(@need_rmt_id))v(rmt_id)   
			LEFT JOIN	Material.RawMaterialType rmt
				ON	v.rmt_id = rmt.rmt_id
	
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
	      	                   WHEN rme.shkrm_id IS NOT NULL THEN 'Штрихкода ' + CAST(v.shkrm_id AS VARCHAR(10)) + ' уже в документе обмена.'
	      	                   ELSE NULL
	      	              END,
			@rmt_id                         = smai.rmt_id,
			@art_id                         = smai.art_id,
			@okei_id                        = smai.okei_id,
			@qty                            = smai.qty,
			@stor_unit_residues_okei_id     = smai.stor_unit_residues_okei_id,
			@stor_unit_residues_qty         = smai.stor_unit_residues_qty,
			@doc_id                         = smai.doc_id,
			@color_id                       = smai.color_id,
			@su_id                          = smai.su_id,
			@frame_width                    = smai.frame_width,
			@is_defected                    = smai.is_defected,
			@nds                            = smai.nds,
			@rmid_id                        = rmid.rmid_id,
			@shksu_id						= rmid.shksu_id,
			@suppliercontract_id			= rmid.suppliercontract_id
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
			LEFT JOIN Material.RawMaterialExchange rme
				ON rme.shkrm_id = sm.shkrm_id
			LEFT JOIN Warehouse.SHKRawMaterialAmount sma
				ON sma.shkrm_id = sm.shkrm_id
	
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	IF NOT EXISTS(
	   	SELECT	1
	   	FROM	Material.ClothColor cc
	   	WHERE	cc.color_id = @need_color_id
	   )
	BEGIN
	    RAISERROR('Цвета с кодом %d не существует', 16, 1, @need_color_id)
	    RETURN
	END
	
	INSERT INTO Material.Article
	  (
	    art_name
	  )
	SELECT	@need_art_name
	WHERE	NOT EXISTS (
	     		SELECT	1
	     		FROM	Material.Article a
	     		WHERE	a.art_name = @need_art_name
	     	)
	
	IF @@ROWCOUNT > 0
	BEGIN
	    SET @need_art_id = SCOPE_IDENTITY()
	END
	ELSE
	BEGIN
	    SELECT	@need_art_id = a.art_id
	    FROM	Material.Article a
	    WHERE	a.art_name = @need_art_name
	END
	
	BEGIN TRY
		BEGIN TRANSACTION	
		
		INSERT INTO Material.RawMaterialExchange
		  (
		    doc_id,
		    doc_type_id,
		    create_dt,
		    create_employee_id,
		    return_dt,
		    return_employee_id,
		    change_dt,
		    change_employee_id,
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
		    need_rmt_id,
		    need_art_id,
		    need_color_id,
		    need_okei_id,
		    need_qty,		    
		    nds,
		    dt,
		    employee_id
		  )
		VALUES
		  (
		    @doc_id,
		    @doc_type_id,
		    @dt,
		    @employee_id,
		    NULL,
		    NULL,
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
		    @need_rmt_id,
		    @need_art_id,
		    @need_color_id,
		    @need_okei_id,
		    @need_qty,
		    @nds,
		    @dt,
		    @employee_id
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
		
		IF @with_log = 1
		BEGIN
		    RAISERROR('Ошибка %d в строке %d  %s', @esev, @estate, @ErrNum, @Line, @Mess) WITH LOG;
		END
		ELSE
		BEGIN
		    RAISERROR('Ошибка %d в строке %d  %s', @esev, @estate, @ErrNum, @Line, @Mess)
		END
	END CATCH 