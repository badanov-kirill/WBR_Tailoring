CREATE PROCEDURE [Material].[RawMaterialExchange_Change]
	@rme_id INT,
	@shkrm_xml XML,
	@employee_id INT
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @dt dbo.SECONDSTIME = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	DECLARE @with_log BIT = 1
	DECLARE @proc_id INT
	DECLARE @data_tab TABLE (
	        	shkrm_id INT,
	        	doc_id INT,
	        	doc_type_id TINYINT,
	        	rmid_id INT,
	        	qty DECIMAL(19, 3),
	        	rmt_id INT,
	        	art_id INT,
	        	color_id INT,
	        	su_id INT,
	        	okei_id INT,
	        	stor_unit_residues_okei_id INT,
	        	stor_unit_residues_qty DECIMAL(9, 3),
	        	is_deleted BIT,
	        	shksu_id INT,
	        	frame_width SMALLINT,
	        	is_defected BIT,
	        	suppliercontract_id INT
	        )
	
	DECLARE @rmid_id INT
	DECLARE @amount DECIMAL(19, 8)
	DECLARE @base_shkrm_id INT
	DECLARE @rmird_out TABLE(rm_invd_id INT, amount DECIMAL(19, 8))
	
	DECLARE @rmiorrd_out TABLE(rmodr_id INT, spcvc_id INT, okei_id INT, quantity DECIMAL(9, 3), operation_num INT)
	DECLARE @rmiord_out TABLE(rmod_id INT, okei_id INT, quantity DECIMAL(9, 3), operation_num INT)
	DECLARE @rmid_out TABLE(rmid_id INT, qty DECIMAL(9, 3), shkrm_id INT)
	DECLARE @doc_id INT
	DECLARE @doc_type_id TINYINT
	DECLARE @sum_qty DECIMAL(19, 3)
	DECLARE @shksu_id INT 
	DECLARE @suppliercontract_id INT
	DECLARE @nds TINYINT
	
	EXECUTE @proc_id = History.ProcId_GetByName @procid = @@PROCID
	
	SELECT	@error_text = CASE 
	      	                   WHEN rme.rme_id IS NULL THEN 'Документа обмена с номером ' + CAST(v.rme_id AS VARCHAR(10)) + ' не существует.'
	      	                   WHEN rme.change_dt IS NOT NULL THEN 'По этому документу уже произошел обмен.'
	      	                   ELSE NULL
	      	              END,
			@rmid_id                 = rme.rmid_id,
			@amount                  = sma.amount * rme.stor_unit_residues_qty / sma.stor_unit_residues_qty,
			@base_shkrm_id           = rme.shkrm_id,
			@doc_id                  = rme.doc_id,
			@doc_type_id             = rme.doc_type_id,
			@shksu_id                = rme.shksu_id,
			@nds                     = rme.nds,
			@suppliercontract_id     = rme.suppliercontract_id
	FROM	(VALUES(@rme_id))v(rme_id)   
			LEFT JOIN	Material.RawMaterialExchange rme
				ON	rme.rme_id = v.rme_id   
			LEFT JOIN	Warehouse.SHKRawMaterialAmount sma
				ON	sma.shkrm_id = rme.shkrm_id
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	INSERT INTO @data_tab
	  (
	    shkrm_id,
	    doc_id,
	    doc_type_id,
	    rmid_id,
	    qty,
	    rmt_id,
	    art_id,
	    color_id,
	    su_id,
	    okei_id,
	    stor_unit_residues_okei_id,
	    stor_unit_residues_qty,
	    is_deleted,
	    shksu_id,
	    frame_width,
	    is_defected,
	    suppliercontract_id
	  )
	SELECT	ml.value('@shkrm[1]', 'int'),
			smai.doc_id,
			smai.doc_type_id,
			rmid.rmid_id,
			smai.qty,
			smai.rmt_id,
			smai.art_id,
			smai.color_id,
			smai.su_id,
			smai.okei_id,
			smai.stor_unit_residues_okei_id,
			smai.stor_unit_residues_qty,
			smai.is_deleted,
			ISNULL(rmid.shksu_id, @shksu_id) shksu_id,
			smai.frame_width,
			smai.is_defected,
			smai.suppliercontract_id
	FROM	@shkrm_xml.nodes('root/det')x(ml)   
			LEFT JOIN	Warehouse.SHKRawMaterialActualInfo smai
				ON	smai.shkrm_id = ml.value('@shkrm[1]',
			'int')   
			LEFT JOIN	Material.RawMaterialIncomeDetail rmid
				ON	rmid.shkrm_id = smai.shkrm_id
				AND	smai.doc_id = rmid.doc_id
				AND	smai.doc_type_id = rmid.doc_type_id  
	
	
	SELECT	@sum_qty = SUM(dt.stor_unit_residues_qty)
	FROM	@data_tab dt
	
	SELECT	@error_text = CASE 
	      	                   WHEN sm.shkrm_id IS NULL THEN 'ШК ' + CAST(dt.shkrm_id AS VARCHAR(10)) + ' не существует.'
	      	                   WHEN dt.doc_id IS NULL THEN 'ШК ' + CAST(dt.shkrm_id AS VARCHAR(10)) + ' не описан'
	      	                   WHEN smai.shkrm_id IS NULL THEN 'ШК ' + CAST(dt.shkrm_id AS VARCHAR(10)) + ' не описан'
	      	                   WHEN ISNULL(sma.amount, 0) != 0 THEN 'У ШК ' + CAST(dt.shkrm_id AS VARCHAR(10)) + ' не нулевая стоимость'
	      	                   WHEN sms.shkrm_id IS NULL THEN 'ШК ' + CAST(dt.shkrm_id AS VARCHAR(10)) + ' не имеет статуса'
	      	                   WHEN rmird.rmid_id IS NOT NULL THEN 'ШК ' + CAST(dt.shkrm_id AS VARCHAR(10)) +
	      	                        ' учавствовал в распределении стоимости счетфактуры, необходимо сначала удалить из распределения.'
	      	                   WHEN rmiord.rmid_id IS NOT NULL THEN 'ШК ' + CAST(dt.shkrm_id AS VARCHAR(10)) +
	      	                        ' учавствовал в распределении заказа пополнение складских остатков, необходимо сначала удалить из распределения.'
	      	                   WHEN rmiorrd.rmid_id IS NOT NULL THEN 'ШК ' + CAST(dt.shkrm_id AS VARCHAR(10)) +
	      	                        ' учавствовал в распределении заказа на резервы, необходимо сначала удалить из распределения.'
	      	                   WHEN oa.cnt > 1 THEN 'ШК ' + CAST(dt.shkrm_id AS VARCHAR(10)) + ' указан более одного раза.'
	      	                   ELSE NULL
	      	              END
	FROM	@data_tab dt   
			LEFT JOIN	Warehouse.SHKRawMaterial sm
				ON	sm.shkrm_id = dt.shkrm_id   
			LEFT JOIN	Warehouse.SHKRawMaterialActualInfo smai
				ON	smai.shkrm_id = sm.shkrm_id   
			LEFT JOIN	Warehouse.SHKRawMaterialState sms   
			INNER JOIN	Warehouse.SHKRawMaterialStateDict smsd
				ON	smsd.state_id = sms.state_id
				ON	sms.shkrm_id = sm.shkrm_id   
			LEFT JOIN	Material.RawMaterialIncomeDetail rmid
				ON	rmid.shkrm_id = dt.shkrm_id
				AND	smai.doc_id = rmid.doc_id
				AND	smai.doc_type_id = rmid.doc_type_id   
			LEFT JOIN	Material.RawMaterialInvoiceRelationDetail rmird
				ON	rmird.rmid_id = rmid.rmid_id   
			LEFT JOIN	Material.RawMaterialIncomeOrderRelationDetail rmiord
				ON	rmiord.rmid_id = rmid.rmid_id   
			LEFT JOIN	Material.RawMaterialIncomeOrderReservRelationDetail rmiorrd
				ON	rmiorrd.rmid_id = rmid.rmid_id   
			LEFT JOIN	Warehouse.SHKRawMaterialAmount sma
				ON	sma.shkrm_id = sm.shkrm_id   
			OUTER APPLY (
			      	SELECT	COUNT(*)      cnt
			      	FROM	@data_tab     dt2
			      	WHERE	dt2.shkrm_id = dt.shkrm_id
			      ) oa
	WHERE	sm.shkrm_id IS NULL
			OR	smai.shkrm_id IS NULL
			OR	sms.shkrm_id IS NULL
			OR	rmird.rmid_id IS NOT NULL
			OR	rmiord.rmid_id IS NOT NULL
			OR	rmiorrd.rmid_id IS NOT NULL
			OR	ISNULL(sma.amount, 0) != 0
			OR	oa.cnt > 1
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	IF (
	   	SELECT	COUNT(DISTINCT sc.supplier_id) cnt
	   	FROM	@data_tab dt   
	   			INNER JOIN	Suppliers.SupplierContract sc
	   				ON	sc.suppliercontract_id = dt.suppliercontract_id
	   ) != 1
	BEGIN
	    RAISERROR('Все заменные шк должны быть от одного поставщика.', 16, 1)
	    RETURN
	END      
	
	BEGIN TRY
		BEGIN TRANSACTION 
		
		UPDATE	Material.RawMaterialExchange
		SET 	change_dt = @dt,
				change_employee_id = @employee_id
		WHERE	rme_id = @rme_id
		
		DELETE	
		FROM	Material.RawMaterialInvoiceRelationDetail
		    	OUTPUT	DELETED.rm_invd_id,
		    			DELETED.amount
		    	INTO	@rmird_out (
		    			rm_invd_id,
		    			amount
		    		)
		WHERE	rmid_id = @rmid_id
		
		DELETE	
		FROM	Material.RawMaterialIncomeOrderReservRelationDetail
		    	OUTPUT	DELETED.rmodr_id,
		    			DELETED.spcvc_id,
		    			DELETED.okei_id,
		    			DELETED.quantity,
		    			DELETED.operation_num
		    	INTO	@rmiorrd_out (
		    			rmodr_id,
		    			spcvc_id,
		    			okei_id,
		    			quantity,
		    			operation_num
		    		)
		WHERE	rmid_id = @rmid_id
		
		DELETE	
		FROM	Material.RawMaterialIncomeOrderRelationDetail
		    	OUTPUT	DELETED.rmod_id,
		    			DELETED.okei_id,
		    			DELETED.quantity,
		    			DELETED.operation_num
		    	INTO	@rmiord_out (
		    			rmod_id,
		    			okei_id,
		    			quantity,
		    			operation_num
		    		)
		WHERE	rmid_id = @rmid_id
		
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
		WHERE	shkrm_id = @base_shkrm_id
		
		DELETE rmrsd
		FROM Suppliers.RawMaterialRefundShkDetail rmrsd
		WHERE rmrsd.rmid_id = @rmid_id
		
		DELETE	rmid
		FROM	Material.RawMaterialIncomeDetail rmid
		WHERE	rmid.rmid_id = @rmid_id
		
		UPDATE	Warehouse.SHKRawMaterialAmount
		SET 	amount = 0
		    	OUTPUT	INSERTED.shkrm_id,
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
		WHERE	shkrm_id = @base_shkrm_id
		
		DELETE	rmid
		FROM	Material.RawMaterialIncomeDetail rmid   
				INNER JOIN	@data_tab dt
					ON	dt.rmid_id = rmid.rmid_id
		
		DELETE	rmp
		FROM	Material.RawMaterialPosting rmp   
				INNER JOIN	@data_tab dt
					ON	dt.doc_id = rmp.doc_id
					AND	dt.doc_type_id = rmp.doc_type_id
					AND	dt.shkrm_id = rmp.shkrm_id
		
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
		   		INSERTED.stor_unit_residues_qty,
		   		INSERTED.shkrm_id
		   INTO	@rmid_out (
		   		rmid_id,
		   		qty,
		   		shkrm_id
		   	)
		SELECT	@doc_id,
				@doc_type_id,
				dt.shkrm_id,
				dt.rmt_id,
				dt.art_id,
				dt.color_id,
				@suppliercontract_id,
				dt.su_id,
				dt.okei_id,
				dt.qty,
				dt.stor_unit_residues_okei_id,
				dt.stor_unit_residues_qty,
				@amount * dt.stor_unit_residues_qty / @sum_qty,
				@nds,
				@dt,
				@employee_id,
				dt.is_deleted,
				dt.shksu_id,
				dt.frame_width,
				dt.is_defected
		FROM	@data_tab dt
		
		UPDATE	smai
		SET 	smai.doc_id = @doc_id,
				smai.doc_type_id = @doc_type_id,
				smai.dt = @dt,
				smai.employee_id = @employee_id,
				smai.nds = @nds
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
		FROM	Warehouse.SHKRawMaterialActualInfo smai
				INNER JOIN	@data_tab dt
					ON	smai.shkrm_id = dt.shkrm_id
		
		UPDATE	smi
		SET 	doc_id = @doc_id,
				doc_type_id = @doc_type_id
				OUTPUT	INSERTED.shkrm_id,
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
		FROM	Warehouse.SHKRawMaterialInfo smi
				INNER JOIN	@data_tab dt
					ON	smi.shkrm_id = dt.shkrm_id
		
		UPDATE	sma
		SET 	amount = @amount * dt.stor_unit_residues_qty / @sum_qty,
				final_dt = @dt				
		    	OUTPUT	INSERTED.shkrm_id,
		    			INSERTED.stor_unit_residues_okei_id,
		    			INSERTED.stor_unit_residues_qty,
		    			INSERTED.amount,
		    			@dt,
		    			@employee_id,
		    			@proc_id,
		    			INSERTED.gross_mass
		    	INTO	History.SHKRawMaterialAmount (
		    			shkrm_id,
		    			stor_unit_residues_okei_id,
		    			stor_unit_residues_qty,
		    			amount,
		    			dt,
		    			employee_id,
		    			proc_id,
		    			gross_mass
		    		)
		FROM	Warehouse.SHKRawMaterialAmount sma
				INNER JOIN	@data_tab dt
					ON	sma.shkrm_id = dt.shkrm_id
		
		INSERT INTO Material.RawMaterialInvoiceRelationDetail
		  (
		    rmid_id,
		    rm_invd_id,
		    amount,
		    doc_id,
		    doc_type_id
		  )
		SELECT	rmido.rmid_id,
				rmirdo.rm_invd_id,
				rmirdo.amount * rmido.qty / @sum_qty,
				@doc_id,
				@doc_type_id
		FROM	@rmird_out rmirdo   
				CROSS JOIN	@rmid_out rmido
		
		INSERT INTO Material.RawMaterialIncomeOrderRelationDetail
		  (
		    rmid_id,
		    rmod_id,
		    okei_id,
		    quantity,
		    doc_id,
		    doc_type_id,
		    operation_num
		  )
		SELECT	rmido.rmid_id,
				rmiordo.rmod_id,
				rmiordo.okei_id,
				rmiordo.quantity * rmido.qty / @sum_qty,
				@doc_id,
				@doc_type_id,
				rmiordo.operation_num
		FROM	@rmiord_out rmiordo   
				CROSS JOIN	@rmid_out rmido
		
		INSERT INTO Material.RawMaterialIncomeOrderReservRelationDetail
		  (
		    rmid_id,
		    rmodr_id,
		    spcvc_id,
		    okei_id,
		    quantity,
		    doc_id,
		    doc_type_id,
		    operation_num
		  )
		SELECT	rmido.rmid_id,
				rmiorrdo.rmodr_id,
				rmiorrdo.spcvc_id,
				rmiorrdo.okei_id,
				rmiorrdo.quantity * rmido.qty / @sum_qty,
				@doc_id,
				@doc_type_id,
				rmiorrdo.operation_num
		FROM	@rmiorrd_out rmiorrdo   
				CROSS JOIN	@rmid_out rmido
		
		INSERT INTO Warehouse.SHKRawMaterialReserv
		  (
		    shkrm_id,
		    spcvc_id,
		    okei_id,
		    quantity,
		    dt,
		    employee_id,
		    rmid_id,
		    rmodr_id
		  )OUTPUT	INSERTED.shkrm_id,
		   		INSERTED.spcvc_id,
		   		INSERTED.okei_id,
		   		INSERTED.quantity,
		   		@dt,
		   		@employee_id,
		   		INSERTED.rmid_id,
		   		INSERTED.rmodr_id,
		   		@proc_id,
		   		'I'
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
		SELECT	rmido.shkrm_id,
				rmiorrdo.spcvc_id,
				rmiorrdo.okei_id,
				rmiorrdo.quantity * rmido.qty / @sum_qty,
				@dt,
				@employee_id,
				rmido.rmid_id,
				rmiorrdo.rmodr_id
		FROM	@rmiorrd_out rmiorrdo   
				CROSS JOIN	@rmid_out rmido
		
		INSERT INTO Material.RawMaterialExchangeDetailChange
		(
			rme_id,
			shkrm_id,
			rmt_id,
			art_id,
			color_id,
			su_id,
			okei_id,
			qty,
			stor_unit_residues_okei_id,
			stor_unit_residues_qty,
			frame_width,
			is_defected,
			dt,
			employee_id
		)
		SELECT	@rme_id,
				dt.shkrm_id,
				dt.rmt_id,
				dt.art_id,
				dt.color_id,
				dt.su_id,
				dt.okei_id,
				dt.qty,
				dt.stor_unit_residues_okei_id,
				dt.stor_unit_residues_qty,
				dt.frame_width,
				dt.is_defected,
				@dt,
				@employee_id
		FROM	@data_tab dt
		
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