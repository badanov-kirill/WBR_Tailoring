CREATE PROCEDURE [Warehouse].[MaterialInProductionDetailShk_Add]
	@mip_id INT,
	@shkrm_id INT,
	@employee_id INT,
	@recive_employee_id INT
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @dt dbo.SECONDSTIME = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	DECLARE @with_log BIT = 1
	DECLARE @shkrm_state_dst INT = 8
	DECLARE @proc_id INT
	DECLARE @place_id INT
	DECLARE @amount DECIMAL(19, 8)
	DECLARE @rmt_id INT
	DECLARE @art_id INT
	DECLARE @okei_id INT
	DECLARE @qty DECIMAL(9, 3)
	DECLARE @rmt_name VARCHAR(100)
	DECLARE @art_name VARCHAR(10)
	DECLARE @okei_symbol VARCHAR(15)	
	DECLARE @nds TINYINT
	DECLARE @gross_mass INT
	DECLARE @stor_unit_residues_okei_id INT
	DECLARE @stor_unit_residues_qty DECIMAL(9, 3)	        
	DECLARE @doc_id INT	        
	DECLARE @doc_type_id TINYINT
	
	EXECUTE @proc_id = History.ProcId_GetByName @procid = @@PROCID
	
	
	SELECT	@error_text = CASE 
	      	                   WHEN mip.mip_id IS NULL THEN 'Заказа в производство с номером ' + CAST(v.mip_id AS VARCHAR(10)) + ' не существует'
	      	                   WHEN mip.complite_dt IS NOT NULL THEN 'Заказ в производство закрыт, добавлять позиции нельзя'
	      	                   WHEN mip.workshop_id IS NULL THEN 'Перед выдачей материалов, необходимо указать цех.'
	      	                   ELSE NULL
	      	              END,
			@place_id = w.place_id
	FROM	(VALUES(@mip_id))v(mip_id)   
			LEFT JOIN	Warehouse.MaterialInProduction mip   
			LEFT JOIN	Warehouse.Workshop w
				ON	w.workshop_id = mip.workshop_id
				ON	mip.mip_id = v.mip_id
	
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
	      	                   WHEN sms.state_id = @shkrm_state_dst THEN 'Штрихкод уже выдан в производство'
	      	                   WHEN smsg.state_src_id IS NULL THEN 'Штрихкод ' + CAST(v.shkrm_id AS VARCHAR(10)) + ' в статусе ' + smsd.state_name +
	      	                        '. Переход в статус ' + smsd2.state_name + ' запрещен.'
	      	                   WHEN mipds.shkrm_id IS NOT NULL THEN 'Штрихкод ' + CAST(v.shkrm_id AS VARCHAR(10)) + ' уже в документе.'
	      	                   WHEN oa.mip_id IS NOT NULL THEN 'Штрихкод ' + CAST(v.shkrm_id AS VARCHAR(10)) + ' числится выданным в документе №' + CAST(oa.mip_id AS VARCHAR(10)) 
	      	                        + ', сначала верните его.'
	      	                   WHEN cis2.shkrm_id IS NOT NULL THEN 'Штрихкод ' + CAST(v.shkrm_id AS VARCHAR(10)) + ' числится выданным в выдачу №' + CAST(cis2.covering_id AS VARCHAR(10)) 
	      	                        + ', сначала верните его.'
	      	                   WHEN mis.shkrm_id IS NOT NULL THEN 'Штрихкод ' + CAST(v.shkrm_id AS VARCHAR(10)) + ' числится выданным на проработку эскиза № ' + CAST(mis.sketch_id AS VARCHAR(10)) 
	      	                        + ', сначала верните его.'
	      	                   ELSE NULL
	      	              END,
			@amount                         = CASE 
													 WHEN sma.stor_unit_residues_okei_id = smai.stor_unit_residues_okei_id OR sma.gross_mass = 0 THEN sma.amount * smai.stor_unit_residues_qty / sma.stor_unit_residues_qty
													 ELSE sma.amount * smai.gross_mass / sma.gross_mass
												END ,
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
			@doc_id                         = smai.doc_id,
			@doc_type_id                    = smai.doc_type_id
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
			LEFT JOIN Warehouse.SHKRawMaterialAmount sma
				ON sma.shkrm_id = sm.shkrm_id    
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
			LEFT JOIN	Warehouse.MaterialInProductionDetailShk mipds
				ON	mipds.mip_id = @mip_id
				AND	mipds.shkrm_id = v.shkrm_id
				AND	mipds.return_dt IS NULL   
			LEFT JOIN	Planing.CoveringIssueSHKRm cis2
				ON	cis2.shkrm_id = sm.shkrm_id
				AND	cis2.return_dt IS NULL
			LEFT JOIN Warehouse.MaterialInSketch mis
				ON mis.shkrm_id = sm.shkrm_id
				AND mis.return_dt IS NULL
			OUTER APPLY (
			      	SELECT	TOP(1) mipds2.mip_id
			      	FROM	Warehouse.MaterialInProductionDetailShk mipds2
			      	WHERE	mipds2.mip_id != @mip_id
			      			AND	mipds2.shkrm_id = v.shkrm_id
			      			AND	mipds2.return_dt IS NULL
			      ) oa	
	
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
		
		;
		MERGE Warehouse.SHKRawMaterialOnPlace t
		USING (
		      	SELECT	@shkrm_id shkrm_id
		      ) s
				ON t.shkrm_id = s.shkrm_id
		WHEN MATCHED THEN 
		     UPDATE	
		     SET 	t.place_id = @place_id,
		     		t.dt = @dt,
		     		t.employee_id = @employee_id
		WHEN NOT MATCHED THEN 
		     INSERT
		     	(
		     		shkrm_id,
		     		place_id,
		     		dt,
		     		employee_id
		     	)
		     VALUES
		     	(
		     		s.shkrm_id,
		     		@place_id,
		     		@dt,
		     		@employee_id
		     	)
		     OUTPUT	INSERTED.shkrm_id,
		     		INSERTED.place_id,
		     		INSERTED.dt,
		     		INSERTED.employee_id,
		     		@proc_id
		     INTO	History.SHKRawMaterialOnPlace (
		     		shkrm_id,
		     		place_id,
		     		dt,
		     		employee_id,
		     		proc_id
		     	);
		
		INSERT INTO Warehouse.MaterialInProductionDetailShk
		  (
		    mip_id,
		    shkrm_id,
		    rmt_id,
		    art_id,
		    okei_id,
		    qty,
		    stor_unit_residues_okei_id,
		    stor_unit_residues_qty,
		    nds,
		    gross_mass,
		    dt,
		    employee_id,
		    recive_employee_id,
		    doc_id,
		    doc_type_id
		  )
		VALUES
		  (
		    @mip_id,
		    @shkrm_id,
		    @rmt_id,
		    @art_id,
		    @okei_id,
		    @qty,
		    @stor_unit_residues_okei_id,
		    @stor_unit_residues_qty,
		    @nds,
		    @gross_mass,
		    @dt,
		    @employee_id,
		    @recive_employee_id,
		    @doc_id,
		    @doc_type_id
		  )
		
		COMMIT TRANSACTION
		
		SELECT	@shkrm_id                   shkrm_id,
				@amount                     amount,
				@rmt_name                   rmt_name,
				@art_name                   art_name,
				@okei_id                    okei_id,
				@okei_symbol                okei_symbol,
				@qty                        qty,
				@stor_unit_residues_okei_id stor_unit_residues_okei_id,
				@stor_unit_residues_qty     stor_unit_residues_qty
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