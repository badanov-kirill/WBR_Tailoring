CREATE PROCEDURE [Logistics].[TTN_ReceiptShkRM]
	@ttn_id INT,
	@shkrm_id INT,
	@employee_id INT,
	@complite_qty DECIMAL(9, 3) = NULL
AS
	SET NOCOUNT ON
	
	DECLARE @dt dbo.SECONDSTIME = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	DECLARE @amount DECIMAL(19, 8)
	DECLARE @rmt_id INT
	DECLARE @art_id INT
	DECLARE @okei_id INT
	DECLARE @qty DECIMAL(9, 3)
	DECLARE @rmt_name VARCHAR(100)
	DECLARE @art_name VARCHAR(10)
	DECLARE @okei_symbol VARCHAR(15)
	DECLARE @shhrm_is_ttn BIT
	DECLARE @nds TINYINT
	DECLARE @gross_mass INT	
	DECLARE @stor_unit_residues_okei_id INT
	DECLARE @stor_unit_residues_qty DECIMAL(9, 3)
	DECLARE @su_name VARCHAR(50)
	
	SELECT	@error_text = CASE 
	      	                   WHEN t.ttn_id IS NULL THEN 'ТТН с номером ' + CAST(v.ttn_id AS VARCHAR(10)) + ' не существует.'
	      	                   WHEN t.complite_dt IS NOT NULL THEN 'ТТН с номером ' + CAST(v.ttn_id AS VARCHAR(10)) + ' уже закрытка.'
	      	                   WHEN s.complite_dt IS NOT NULL THEN 'Отгрузка № ' + CAST(s.shipping_id AS VARCHAR(10)) + ' уже обработана'
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
	
	SELECT	@error_text = CASE 
	      	                   WHEN sm.shkrm_id IS NULL THEN 'Штрихкода ' + CAST(v.shkrm_id AS VARCHAR(10)) + ' не существует.'
	      	                   WHEN sma.shkrm_id IS NULL THEN 'Штрихкода ' + CAST(v.shkrm_id AS VARCHAR(10)) + ' не имеет цены.'
	      	                   WHEN smai.shkrm_id IS NULL THEN 'Штрихкод ' + CAST(v.shkrm_id AS VARCHAR(10)) +
	      	                        ' не описан.'
	      	                   ELSE NULL
	      	              END,
			@amount                         = ISNULL(CASE 
			                                              WHEN sma.stor_unit_residues_okei_id = t.stor_unit_residues_okei_id OR sma.gross_mass = 0 
			                                              THEN sma.amount * t.stor_unit_residues_qty / sma.stor_unit_residues_qty
			                                              ELSE sma.amount * t.gross_mass / sma.gross_mass
			                                         END, 
			                                         CASE 
			                                              WHEN sma.stor_unit_residues_okei_id = smai.stor_unit_residues_okei_id OR sma.gross_mass = 0 
			                                              THEN sma.amount * smai.stor_unit_residues_qty / sma.stor_unit_residues_qty
			                                              ELSE sma.amount * smai.gross_mass / sma.gross_mass
			                                         END),
			@rmt_id                         = ISNULL(t.rmt_id, smai.rmt_id),
			@art_id                         = ISNULL(t.art_id, smai.art_id),
			@okei_id                        = ISNULL(t.okei_id, smai.okei_id),
			@qty                            = ISNULL(t.qty, smai.qty),
			@rmt_name                       = ISNULL(rmtt.rmt_name, rmt.rmt_name),
			@art_name                       = ISNULL(at.art_name, a.art_name),
			@okei_symbol                    = ISNULL(ot.symbol, o.symbol),
			@shhrm_is_ttn                   = CASE 
			                     WHEN t.shkrm_id IS NULL THEN 0
			                     ELSE 1
			                END,
			@nds                            = ISNULL(t.nds, smai.nds),
			@gross_mass                     = ISNULL(t.gross_mass, smai.gross_mass),
			@stor_unit_residues_okei_id     = ISNULL(t.stor_unit_residues_okei_id, smai.stor_unit_residues_okei_id),
			@stor_unit_residues_qty         = ISNULL(t.stor_unit_residues_qty, smai.stor_unit_residues_qty),
			@su_name						= ISNULL(su2.su_name, su.su_name)
	FROM	(VALUES(@shkrm_id))v(shkrm_id)   
			LEFT JOIN	Warehouse.SHKRawMaterial sm
				ON	sm.shkrm_id = v.shkrm_id   
			LEFT JOIN Warehouse.SHKRawMaterialAmount sma
				ON sma.shkrm_id = sm.shkrm_id
			LEFT JOIN	Warehouse.SHKRawMaterialActualInfo smai   
			INNER JOIN	Material.RawMaterialType rmt
				ON	rmt.rmt_id = smai.rmt_id   
			INNER JOIN	Material.Article a
				ON	a.art_id = smai.art_id   
			INNER JOIN	Qualifiers.OKEI o
				ON	o.okei_id = smai.okei_id
			INNER JOIN RefBook.SpaceUnit su
				ON su.su_id = smai.su_id			
				ON	smai.shkrm_id = v.shkrm_id   
			LEFT JOIN	Logistics.TTNDetail t   
			INNER JOIN	Material.RawMaterialType rmtt
				ON	rmtt.rmt_id = t.rmt_id   
			INNER JOIN	Material.Article at
				ON	at.art_id = t.art_id   
			INNER JOIN	Qualifiers.OKEI ot
				ON	ot.okei_id = t.okei_id
			INNER JOIN RefBook.SpaceUnit su2
				ON su2.su_id = t.su_id
				ON	v.shkrm_id = t.shkrm_id
				AND	t.ttn_id = @ttn_id
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	BEGIN TRY
		IF @shhrm_is_ttn = 1
		BEGIN
		    UPDATE	Logistics.TTNDetail
		    SET 	complite_qty             = ISNULL(@complite_qty, qty),
		    		complite_employee_id     = @employee_id,
		    		complite_dt              = @dt
		    WHERE	ttn_id                   = @ttn_id
		    		AND	shkrm_id             = @shkrm_id
		    		AND	complite_dt IS NULL
		END
		ELSE
		BEGIN
		    INSERT INTO Logistics.TTNDivergenceAct
		      (
		        create_employee_id,
		        create_dt,
		        ttn_id,
		        shkrm_id,
		        rmt_id,
		        art_id,
		        okei_id,
		        nds,
		        gross_mass,
		        divergence_qty,
		        comment,
		        write_of_qty,
		        write_of_employee_id,
		        write_of_dt,
		        write_of_comment,
		        complite_employee_id,
		        complite_dt,
		        stor_unit_residues_okei_id,
		        stor_unit_residues_qty
		      )
		    SELECT	@employee_id,
		    		@dt,
		    		@ttn_id,
		    		@shkrm_id,
		    		@rmt_id,
		    		@art_id,
		    		@okei_id,
		    		@nds,
		    		@gross_mass,
		    		-ISNULL(@complite_qty, @qty),
		    		NULL,
		    		NULL,
		    		NULL,
		    		NULL,
		    		NULL,
		    		NULL,
		    		NULL,
		    		@stor_unit_residues_okei_id,
		    		@stor_unit_residues_qty
		    WHERE	NOT EXISTS (
		         		SELECT	1
		         		FROM	Logistics.TTNDivergenceAct tda
		         		WHERE	tda.ttn_id = @ttn_id
		         				AND	tda.shkrm_id = @shkrm_id
		         	)
		END
		
		SELECT	@shkrm_id                   shkrm_id,
				@amount                     amount,
				@rmt_name                   rmt_name,
				@art_name                   art_name,
				@okei_id                    okei_id,
				@okei_symbol                okei_symbol,
				@qty                        qty,
				@nds                        nds,
				@gross_mass                 gross_mass,
				@stor_unit_residues_okei_id stor_unit_residues_okei_id,
				@stor_unit_residues_qty     stor_unit_residues_qty,
				@su_name					su_name
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