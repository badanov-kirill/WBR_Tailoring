CREATE PROCEDURE [Logistics].[TTNDetail_Add]
	@shkrm_id INT,
	@employee_id INT,
	@ttn_id INT
AS
	SET NOCOUNT ON
	DECLARE @dt dbo.SECONDSTIME = GETDATE()
	DECLARE @with_log BIT = 1
	DECLARE @error_text VARCHAR(MAX)
	DECLARE @shkrm_state_dst INT = 4
	DECLARE @amount DECIMAL(19, 8)
	DECLARE @rmt_id INT
	DECLARE @art_id INT
	DECLARE @okei_id INT
	DECLARE @qty DECIMAL(9, 3)
	DECLARE @rmt_name VARCHAR(100)
	DECLARE @art_name VARCHAR(10)
	DECLARE @okei_symbol VARCHAR(15)	
	DECLARE @proc_id INT
	DECLARE @nds TINYINT
	DECLARE @su_id INT
	DECLARE @gross_mass INT
	DECLARE @stor_unit_residues_okei_id INT
	DECLARE @stor_unit_residues_qty DECIMAL(9, 3)
	DECLARE @ps_id INT
	DECLARE @ttn_detail_output TABLE (ttnd_id INT)
	
	EXECUTE @proc_id = History.ProcId_GetByName @procid = @@PROCID
	
	SELECT	@error_text = CASE 
	      	                   WHEN t.ttn_id IS NULL THEN 'ТТН с номером ' + CAST(v.ttn_id AS VARCHAR(10)) + ' не существует.'
	      	                   WHEN t.complite_dt IS NOT NULL THEN 'ТТН с номером ' + CAST(v.ttn_id AS VARCHAR(10)) + ' уже закрытка.'
	      	                   WHEN s.close_dt IS NOT NULL THEN 'Отгрузка № ' + CAST(s.shipping_id AS VARCHAR(10)) + ' уже отправлена'
	      	                   ELSE NULL
	      	              END
	FROM	(VALUES(@ttn_id))v(ttn_id)   
			LEFT JOIN	Logistics.TTN t
				ON	t.ttn_id = v.ttn_id   
			LEFT JOIN	Logistics.Shipping s
				ON	s.shipping_id = t.shipping_id	
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	SELECT	@ps_id = ps.ps_id
	FROM	Planing.PlanShipping ps
	WHERE	ps.ttn_id = @ttn_id
	
	SELECT	@error_text = CASE 
	      	                   WHEN sma.shkrm_id IS NULL THEN 'Штрихкода ' + CAST(v.shkrm_id AS VARCHAR(10)) + ' не имеет цены.'
	      	                   WHEN sm.shkrm_id IS NULL THEN 'Штрихкода ' + CAST(v.shkrm_id AS VARCHAR(10)) + ' не существует.'
	      	                   WHEN smai.shkrm_id IS NULL THEN 'Штрихкод ' + CAST(v.shkrm_id AS VARCHAR(10)) +
	      	                        ' не описан.'
	      	                   WHEN sms.shkrm_id IS NULL THEN 'У штрихкода ' + CAST(v.shkrm_id AS VARCHAR(10)) +
	      	                        ' нет статуса, операции со штрихкодом запрещены. Обратитесь к руководителю'
	      	                   WHEN sms.state_id = @shkrm_state_dst THEN 'Штрихкод уже подготовлен к отгрузке'	      	                   
	      	                   WHEN smsg.state_src_id IS NULL THEN 'Штрихкод ' + CAST(v.shkrm_id AS VARCHAR(10)) + ' в статусе ' + smsd.state_name +
	      	                        '. Переход в статус ' + smsd2.state_name + ' запрещен.'
	      	                   WHEN t.shkrm_id IS NOT NULL THEN 'Штрихкод ' + CAST(v.shkrm_id AS VARCHAR(10)) + ' уже в документе.'	
	      	                   WHEN psd.shkrm_id IS NOT NULL THEN 'Штрихкод ' + CAST(v.shkrm_id AS VARCHAR(10)) + ' находится в плановой отгрузке номер '
	      						+ CAST(@ps_id AS VARCHAR(10)) + ' , которая не связана с этим ТТН.'       	                   
	      	                   ELSE NULL
	      	              END,
			@amount                         = CASE 
			                                       WHEN sma.stor_unit_residues_okei_id = smai.stor_unit_residues_okei_id OR sma.gross_mass = 0
			                                       THEN sma.amount * smai.stor_unit_residues_qty / sma.stor_unit_residues_qty 
			                                       ELSE sma.amount * smai.gross_mass / sma.gross_mass
			                                  END,
			@rmt_id                         = smai.rmt_id,
			@art_id                         = smai.art_id,
			@okei_id                        = smai.okei_id,
			@qty                            = smai.qty,
			@rmt_name                       = rmt.rmt_name,
			@art_name                       = a.art_name,
			@okei_symbol                    = o.symbol,
			@nds                            = smai.nds,
			@gross_mass                     = smai.gross_mass,
			@stor_unit_residues_okei_id     = smai.stor_unit_residues_okei_id,
			@stor_unit_residues_qty         = smai.stor_unit_residues_qty,
			@su_id							= smai.su_id
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
			INNER JOIN	Material.RawMaterialType rmt
				ON	rmt.rmt_id = smai.rmt_id   
			INNER JOIN	Material.Article a
				ON	a.art_id = smai.art_id   
			INNER JOIN	Qualifiers.OKEI o
				ON	o.okei_id = smai.okei_id
				ON	smai.shkrm_id = v.shkrm_id
			LEFT JOIN Logistics.TTNDetail t
				ON t.ttn_id = @ttn_id AND t.shkrm_id = v.shkrm_id
			LEFT JOIN Warehouse.SHKRawMaterialAmount sma
				ON sma.shkrm_id = sm.shkrm_id
			LEFT JOIN Planing.PlanShippingDetail psd
				ON psd.shkrm_id = sm.shkrm_id
				AND psd.shipping_dt IS NULL
				AND psd.ttnd_id IS NULL
				AND @ps_id IS NULL
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	BEGIN TRY
		BEGIN TRANSACTION		
		
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
		
		INSERT INTO Logistics.TTNDetail
		  (
		    ttn_id,
		    shkrm_id,
		    rmt_id,
		    art_id,
		    okei_id,
		    qty,
		    employee_id,
		    dt,
		    nds,
		    gross_mass,
		    stor_unit_residues_okei_id,
		    stor_unit_residues_qty,
		    su_id
		  )OUTPUT INSERTED.ttnd_id INTO @ttn_detail_output(ttnd_id)
		VALUES
		  (
		    @ttn_id,
		    @shkrm_id,
		    @rmt_id,
		    @art_id,
		    @okei_id,
		    @qty,
		    @employee_id,
		    @dt,
		    @nds,
		    @gross_mass,
		    @stor_unit_residues_okei_id,
		    @stor_unit_residues_qty,
		    @su_id
		  )
		  
		  UPDATE	psd
		  SET 	ttnd_id = tdo.ttnd_id
		  FROM	Planing.PlanShippingDetail psd
		  		CROSS JOIN	@ttn_detail_output tdo
		  WHERE	psd.ps_id = @ps_id
		  		AND	psd.shkrm_id = @shkrm_id
		
		COMMIT TRANSACTION
		
		SELECT	@shkrm_id                   shkrm_id,
				@amount                     amount,
				@rmt_name                   rmt_name,
				@art_name                   art_name,
				@okei_id                    okei_id,
				@okei_symbol                okei_symbol,
				@qty                        qty,
				@stor_unit_residues_okei_id stor_unit_residues_okei_id,
				@stor_unit_residues_qty     stor_unit_residues_qty,
				tdo.ttnd_id
		FROM @ttn_detail_output tdo
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