
CREATE PROCEDURE [Warehouse].[SHKRawMaterial_RestoreByCovering]
	@shkrm_id INT,
	@qty DECIMAL(9, 3),
	@employee_id INT
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @dt DATETIME2(0) = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	DECLARE @proc_id INT
	DECLARE @cisr_id INT 
	DECLARE @stor_unit_residues_qty DECIMAL(9, 3)
	DECLARE @okei_id INT	        
	DECLARE @stor_unit_residues_okei_id INT
	DECLARE @gross_mass INT
	DECLARE @place_id INT = 1067
	DECLARE @shkrm_state_dst INT = 9
	DECLARE @is_full BIT
	
	EXECUTE @proc_id = History.ProcId_GetByName @procid = @@PROCID
	
	SELECT	@error_text = CASE 
	      	                   WHEN sm.shkrm_id IS NULL THEN 'Штрихкода ' + CAST(v.shkrm_id AS VARCHAR(10)) + ' не существует.'
	      	                   WHEN sm.shkrm_id IS NOT NULL AND sma.shkrm_id IS NULL THEN 'Штрихкод ' + CAST(v.shkrm_id AS VARCHAR(10)) +
	      	                        ' не имел цены, обратитесь к разработчику.'
	      	                   WHEN sm.shkrm_id IS NOT NULL AND cis.cisr_id IS NULL THEN 'Штрихкод ' + CAST(v.shkrm_id AS VARCHAR(10)) +
	      	                        ' не найден списанным в выдаче по конфекционной карте.'
	      	                   WHEN @qty > cis.qty THEN 'Нельзя восстановить больше, чем было.'
	      	                   WHEN cis.return_qty != 0 AND smai.shkrm_id IS NULL THEN 'Штрихкод списан полностью не по конфекционной карте'
	      	                   WHEN cis.return_qty != 0 AND cis.return_qty != smai.qty THEN 
	      	                        'Количество возврата по выдаче не совпадеает с текущим остатком по шк'
	      	                   WHEN cis.return_qty = 0 AND smai.shkrm_id IS NOT NULL THEN 
	      	                        'Штрихкод списан полностью по конфекционной карте, но имеет остаток, обратитесь к разработчику'
	      	                   WHEN cis.qty IS NOT NULL AND cis.return_qty IS NULL THEN 'Штрихкод выдан, но не списан. Сделайте возврат стандартным способом.'
	      	                   ELSE NULL
	      	              END,
			@cisr_id = cis.cisr_id,
			@stor_unit_residues_qty = @qty * cis.stor_unit_residues_qty / cis.qty,
			@okei_id = cis.okei_id,
			@stor_unit_residues_okei_id = cis.stor_unit_residues_okei_id,
			@gross_mass = (@qty * cis.stor_unit_residues_qty / cis.qty) * (sma.gross_mass / sma.stor_unit_residues_qty),
			@is_full = CASE 
			                WHEN smai.shkrm_id IS NOT NULL THEN 0
			                ELSE 1
			           END
	FROM	(VALUES(@shkrm_id))v(shkrm_id)   
			LEFT JOIN	Warehouse.SHKRawMaterial sm
				ON	sm.shkrm_id = v.shkrm_id   
			LEFT JOIN	Warehouse.SHKRawMaterialActualInfo smai
				ON	smai.shkrm_id = sm.shkrm_id   
			LEFT JOIN	Warehouse.SHKRawMaterialAmount sma
				ON	sma.shkrm_id = v.shkrm_id   
			OUTER APPLY (
			      	SELECT	TOP(1) cisr.cisr_id,
			      			cisr.qty,
			      			cisr.stor_unit_residues_qty,
			      			cisr.stor_unit_residues_okei_id,
			      			cisr.okei_id,
			      			cisr.return_qty
			      	FROM	Planing.CoveringIssueSHKRm cisr
			      	WHERE	cisr.shkrm_id = v.shkrm_id
			      	ORDER BY
			      		cisr.cisr_id DESC
			      ) cis
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	BEGIN TRY
		BEGIN TRANSACTION	
		
		IF @is_full = 1
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
		    		@okei_id,
		    		@qty,
		    		@stor_unit_residues_okei_id,
		    		@stor_unit_residues_qty,
		    		@dt,
		    		@employee_id,
		    		smi.frame_width,
		    		0,
		    		0,
		    		smi.nds,
		    		@gross_mass,
		    		smi.tissue_density,
					ri.fabricator_id
		    FROM	Warehouse.SHKRawMaterialInfo smi
				left JOIN Material.RawMaterialIncome ri on  ri.doc_id = smi.doc_id and ri.doc_type_id = smi.doc_type_id
		    WHERE	smi.shkrm_id = @shkrm_id
		    
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
		    UPDATE	Warehouse.SHKRawMaterialActualInfo
		    SET 	qty             = @qty,
		    		stor_unit_residues_qty = @stor_unit_residues_qty,
		    		dt              = @dt,
		    		employee_id     = @employee_id
		    		OUTPUT	INSERTED.shkrm_id,
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
		    WHERE	shkrm_id = @shkrm_id
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
		
		UPDATE	Planing.CoveringIssueSHKRm
		SET 	return_qty = @qty,
				return_dt = @dt,
				return_employee_id = @employee_id,
				return_recive_employee_id = @employee_id,
				return_stor_unit_residues_qty = @stor_unit_residues_qty
		WHERE	cisr_id = @cisr_id
		
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