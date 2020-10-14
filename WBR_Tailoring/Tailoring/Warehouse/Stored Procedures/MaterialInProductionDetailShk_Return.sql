CREATE PROCEDURE [Warehouse].[MaterialInProductionDetailShk_Return]
	@mipds_id INT,
	@employee_id INT,
	@return_employee_id INT,
	@retyrn_qty DECIMAL(9, 3)
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @dt dbo.SECONDSTIME = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	DECLARE @with_log BIT = 1
	DECLARE @shkrm_state_dst INT = 9
	DECLARE @proc_id INT
	DECLARE @place_id INT
	DECLARE @return_stor_unit_residues_qty DECIMAL(9, 3)
	DECLARE @retyrn_gross_mass INT
	DECLARE @shkrm_id INT
	DECLARE @mip_id INT
	
	EXECUTE @proc_id = History.ProcId_GetByName @procid = @@PROCID
	
	SELECT	@error_text = CASE 
	      	                   WHEN mipds.mipds_id IS NULL THEN 'Строки документа ' + CAST(v.mipds_id AS VARCHAR(10)) + ' не существует.'
	      	                   WHEN mipds.return_dt IS NOT NULL THEN 'Этот ШК ' + CAST(mipds.shkrm_id AS VARCHAR(10)) + ' (' + rmt.rmt_name +
	      	                        ') уже вернули в количестве ' + CAST(mipds.return_qty AS VARCHAR(10)) + ' ' + o.symbol
	      	                   WHEN smai.shkrm_id IS NULL THEN 'Нет описания ШК. Обратитесь к разработчику'
	      	                   WHEN mipds.rmt_id != smai.rmt_id OR mipds.art_id != smai.art_id OR mipds.qty != smai.qty OR mipds.okei_id 
	      	                        != smai.okei_id THEN 'По этому ШК ' + CAST(mipds.shkrm_id AS VARCHAR(10)) +
	      	                        ' не совтадают данные выдачи и текущие данные по шк. Обратитесь к разработчику' + CHAR(10) +
	      	                        'Кол-во ' + CAST(smai.qty AS VARCHAR(10)) + ' и ' + CAST(mipds.qty AS VARCHAR(10)) + CHAR(10) +
	      	                        'ОКЕИ ' + CAST(smai.okei_id AS VARCHAR(10)) + ' и ' + CAST(mipds.okei_id AS VARCHAR(10)) + CHAR(10) +
	      	                        'Код типа ' + CAST(smai.rmt_id AS VARCHAR(10)) + ' и ' + CAST(mipds.art_id AS VARCHAR(10)) + CHAR(10) +
	      	                        'Код артикула' + + CAST(smai.art_id AS VARCHAR(10)) + ' и ' + CAST(mipds.art_id AS VARCHAR(10))
	      	                   WHEN sms.shkrm_id IS NULL THEN 'У штрихкода ' + CAST(mipds.shkrm_id AS VARCHAR(10)) +
	      	                        ' нет статуса, операции со штрихкодом запрещены. Обратитесь к руководителю'
	      	                   WHEN smsg.state_src_id IS NULL THEN 'Штрихкод ' + CAST(mipds.shkrm_id AS VARCHAR(10)) + ' в статусе ' + smsd.state_name +
	      	                        '. Переход в статус ' + smsd2.state_name + ' запрещен.'
	      	                   ELSE NULL
	      	              END,
			@return_stor_unit_residues_qty = @retyrn_qty * mipds.stor_unit_residues_qty / mipds.qty,
			@shkrm_id = mipds.shkrm_id,
			@place_id = w.return_place_id,
			@mip_id = mipds.mip_id,
			@retyrn_gross_mass = smai.gross_mass * @retyrn_qty / smai.qty
	FROM	(VALUES(@mipds_id))v(mipds_id)   
			LEFT JOIN	Warehouse.MaterialInProductionDetailShk mipds   
			INNER JOIN	Warehouse.MaterialInProduction mip   
			INNER JOIN	Warehouse.Workshop w
				ON	w.workshop_id = mip.workshop_id
				ON	mip.mip_id = mipds.mip_id   
			INNER JOIN	Material.RawMaterialType rmt
				ON	rmt.rmt_id = mipds.rmt_id   
			INNER JOIN	Qualifiers.OKEI o
				ON	o.okei_id = mipds.okei_id   
			LEFT JOIN	Warehouse.SHKRawMaterialActualInfo smai
				ON	smai.shkrm_id = mipds.shkrm_id   
			LEFT JOIN	Warehouse.SHKRawMaterialState sms   
			INNER JOIN	Warehouse.SHKRawMaterialStateDict smsd
				ON	smsd.state_id = sms.state_id   
			LEFT JOIN	Warehouse.SHKRawMaterialStateGraph smsg
				ON	sms.state_id = smsg.state_src_id
				AND	smsg.state_dst_id = @shkrm_state_dst
				ON	sms.shkrm_id = mipds.shkrm_id
				ON	mipds.mipds_id = v.mipds_id   
			LEFT  JOIN	Warehouse.SHKRawMaterialStateDict smsd2
				ON	smsd2.state_id = @shkrm_state_dst   
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	BEGIN TRY
		BEGIN TRANSACTION		
		
		DELETE	
		FROM	Warehouse.SHKRawMaterialReserv
		    	OUTPUT	DELETED.shkrm_id,
		    			DELETED.spcvc_id,
		    			DELETED.okei_id,
		    			DELETED.quantity,
		    			@dt,
		    			@employee_id,
		    			DELETED.rmid_id,
		    			DELETED.rmodr_id,
		    			@proc_id,
		    			'D'
		    	INTO	History.SHKRawMaterialReserv (
		    			shkrm_id,
		    			spcvc_id,
		    			okei_id,
		    			quantity,
		    			dt,
		    			employee_id,
		    			rmid_id,
		    			rmodr_id,
		    			proc_id,
		    			operation
		    		)
		WHERE	shkrm_id = @shkrm_id
		
		IF @retyrn_qty = 0
		BEGIN
		    DELETE	
		    FROM	Warehouse.SHKRawMaterialActualInfo
		        	OUTPUT	DELETED.shkrm_id,
		        			@dt,
		        			@employee_id,
		        			@proc_id
		        	INTO	History.SHKRawMaterialActualInfo (
		        			shkrm_id,
		        			dt,
		        			employee_id,
		        			proc_id
		        		)
		    WHERE	shkrm_id = @shkrm_id
		    
		    DELETE	
		    FROM	Warehouse.SHKRawMaterialDefectDescr
		        	OUTPUT	DELETED.shkrm_id,
		        			NULL,
		        			@dt,
		        			@employee_id,
		        			@proc_id
		        	INTO	History.SHKRawMaterialDefectDescr (
		        			shkrm_id,
		        			descr,
		        			dt,
		        			employee_id,
		        			proc_id
		        		)
		    WHERE	shkrm_id = @shkrm_id
		    
		    
		    DELETE	
		    FROM	Warehouse.SHKRawMaterialState
		        	OUTPUT	DELETED.shkrm_id,
		        			NULL,
		        			@dt,
		        			@employee_id,
		        			@proc_id
		        	INTO	History.SHKRawMaterialState (
		        			shkrm_id,
		        			state_id,
		        			dt,
		        			employee_id,
		        			proc_id
		        		)
		    WHERE	shkrm_id = @shkrm_id
		    
		    DELETE	
		    FROM	Warehouse.SHKRawMaterialOnPlace
		        	OUTPUT	DELETED.shkrm_id,
		        			NULL,
		        			@dt,
		        			@employee_id,
		        			@proc_id
		        	INTO	History.SHKRawMaterialOnPlace (
		        			shkrm_id,
		        			place_id,
		        			dt,
		        			employee_id,
		        			proc_id
		        		)
		    WHERE	shkrm_id = @shkrm_id
		END
		ELSE
		BEGIN
		    UPDATE	Warehouse.SHKRawMaterialActualInfo
		    SET 	qty = @retyrn_qty,
		    		stor_unit_residues_qty = @return_stor_unit_residues_qty,
		    		gross_mass = @retyrn_gross_mass,
		    		dt = @dt,
		    		employee_id = @employee_id
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
		END
		
		UPDATE	Warehouse.MaterialInProductionDetailShk
		SET 	return_qty = @retyrn_qty,
				return_dt = @dt,
				return_employee_id = @return_employee_id,
				return_recive_employee_id = @employee_id
		WHERE	mipds_id = @mipds_id
		
		
		
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