
CREATE PROCEDURE [Material].[RawMaterialExchange_Cancel]
	@rme_id INT,
	@employee_id INT
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @dt dbo.SECONDSTIME = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	DECLARE @proc_id INT
	EXECUTE @proc_id = History.ProcId_GetByName @procid = @@PROCID
	
	DECLARE @place_id INT = 1067
	DECLARE @shkrm_state_dst INT = 3
	DECLARE @is_return BIT
	DECLARE @gross_mass INT
	DECLARE @tissue_density SMALLINT
	DECLARE @shkrm_id INT
	
	SELECT	@error_text = CASE 
	      	                   WHEN rme.rme_id IS NULL THEN 'Документа обмена с номером ' + CAST(v.rme_id AS VARCHAR(10)) + ' не существует.'
	      	                   WHEN rme.change_dt IS NOT NULL THEN 'По этому документу уже произошел обмен, откатывать нельзя.'
	      	                   WHEN oas.rmed_id IS NOT NULL THEN 'Произведена замена, откатывать нельзя.'
	      	                   ELSE NULL
	      	              END,
			@shkrm_id           = rme.shkrm_id,
			@gross_mass         = sma.gross_mass,
			@tissue_density     = smi.tissue_density,
			@is_return          = CASE 
			                  WHEN smai.shkrm_id IS NOT NULL THEN 0
			                  ELSE 1
			             END
	FROM	(VALUES(@rme_id))v(rme_id)   
			LEFT JOIN	Material.RawMaterialExchange rme
				ON	rme.rme_id = v.rme_id   
			LEFT JOIN	Warehouse.SHKRawMaterialAmount sma
				ON	sma.shkrm_id = rme.shkrm_id   
			LEFT JOIN	Warehouse.SHKRawMaterial sm
				ON	sm.shkrm_id = rme.shkrm_id   
			LEFT JOIN	Warehouse.SHKRawMaterialActualInfo smai
				ON	smai.shkrm_id = sm.shkrm_id   
			LEFT JOIN	Warehouse.SHKRawMaterialInfo smi
				ON	smi.shkrm_id = sm.shkrm_id   
			OUTER APPLY (
			      	SELECT	TOP(1) rmedc.rmed_id
			      	FROM	Material.RawMaterialExchangeDetailChange rmedc
			      	WHERE	rmedc.rme_id = rme.rme_id
			      ) oas
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	BEGIN TRY
		BEGIN TRANSACTION	
		
		IF @is_return = 1
		BEGIN 
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
						INSERTED.fabricator_id
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
		    SELECT	smi.shkrm_id,
		    		smi.doc_id,
		    		smi.doc_type_id,
		    		smi.suppliercontract_id,
		    		smi.rmt_id,
		    		smi.art_id,
		    		smi.color_id,
		    		smi.su_id,
		    		smi.okei_id,
		    		smi.qty,
		    		smi.stor_unit_residues_okei_id,
		    		smi.stor_unit_residues_qty,
		    		@dt,
		    		@employee_id,
		    		smi.frame_width,
		    		0,
		    		0,
		    		smi.nds,
		    		@gross_mass,
		    		@tissue_density,
					ri.fabricator_id
		    FROM	Material.RawMaterialExchange smi
				INNER JOIN Material.RawMaterialIncome ri on  ri.doc_id = smi.doc_id and ri.doc_type_id = smi.doc_type_id
				INNER JOIN Settings.Fabricators f on f.fabricator_id = ri.fabricator_id
		    WHERE	smi.rme_id = @rme_id
		    
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
		    		@shkrm_state_dst,
		    		@dt,
		    		@employee_id
		    	)
		END
		ELSE
		BEGIN
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
		    WHERE	s.shkrm_id = @shkrm_id
		END;
		
		
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
		
		DELETE	rme
		FROM	Material.RawMaterialExchange rme
		WHERE	rme.rme_id = @rme_id
		
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
		
		RAISERROR('Ошибка %d в строке %d  %s', @esev, @estate, @ErrNum, @Line, @Mess) 
		--WITH LOG;
	END CATCH
GO	