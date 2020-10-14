CREATE PROCEDURE [Warehouse].[Inventory_Close]
	@inventory_id INT,
	@employee_id INT,
	@only_data BIT = 0
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @dt DATETIME2(0) = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	DECLARE @it_id TINYINT
	DECLARE @lost_sum DECIMAL(15, 2)
	DECLARE @proc_id INT
	EXECUTE @proc_id = History.ProcId_GetByName @procid = @@PROCID
	DECLARE @shkrm_state_dst INT = 22
	
	DECLARE @lost_tab TABLE (shkrm_id INT, place_id INT, okei_id INT, qty DECIMAL(9, 3), stor_unit_residues_okei_id INT, stor_unit_residues_qty DECIMAL(9, 3), amount DECIMAL(19, 8))
	
	SELECT	@error_text = CASE 
	      	                   WHEN i.inventory_id IS NULL THEN 'Инвентаризации с кодом ' + CAST(v.inventory_id AS VARCHAR(10)) + ' не существует'
	      	                   WHEN i.close_dt IS NOT NULL THEN 'Инвентаризация № ' + CAST(v.inventory_id AS VARCHAR(10)) +
	      	                        ' уже закрыта.'
	      	                   ELSE NULL
	      	              END,
			@it_id = i.it_id
	FROM	(VALUES(@inventory_id))v(inventory_id)   
			LEFT JOIN	Warehouse.Inventory i
				ON	i.inventory_id = v.inventory_id
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	IF EXISTS (
	   	SELECT	1
	   	FROM	Warehouse.InventoryLostShkRM ilsr
	   	WHERE	ilsr.inventory_id = @inventory_id
	   )
	BEGIN
	    RAISERROR('Документ уже содержит потерянные шк, обратитесь к разработчику', 16, 1)
	    RETURN
	END
	
	IF NOT EXISTS (
	   	SELECT	1
	   	FROM	Warehouse.InventoryShkRM isr
	   	WHERE	isr.inventory_id = @inventory_id
	   )
	BEGIN
	    RAISERROR('В инвентаризацию не запикано ни одного шк', 16, 1)
	    RETURN
	END
	
	IF @it_id = 1
	BEGIN
	    INSERT INTO @lost_tab
	    	(
	    		shkrm_id,
	    		place_id,
	    		okei_id,
	    		qty,
	    		stor_unit_residues_okei_id,
	    		stor_unit_residues_qty,
	    		amount
	    	)
	    SELECT	smop.shkrm_id,
	    		smop.place_id,
	    		smai.okei_id,
	    		smai.qty,
	    		smai.stor_unit_residues_okei_id,
	    		smai.stor_unit_residues_qty,
	    		ISNULL(sma.amount * smai.stor_unit_residues_qty / sma.stor_unit_residues_qty, 0) amount
	    FROM	Warehouse.SHKRawMaterialOnPlace smop   
	    		INNER JOIN	Warehouse.InventoryStoragePlace isp
	    			ON	isp.place_id = smop.place_id   
	    		INNER JOIN	Warehouse.SHKRawMaterialActualInfo smai
	    			ON	smai.shkrm_id = smop.shkrm_id   
	    		LEFT JOIN	Warehouse.SHKRawMaterialAmount sma
	    			ON	sma.shkrm_id = smop.shkrm_id   
	    		LEFT JOIN	Warehouse.InventoryShkRM insr
	    			ON	insr.inventory_id = isp.inventory_id
	    			AND	insr.shkrm_id = smop.shkrm_id   
	    		LEFT JOIN	(SELECT	isr.inventory_id,
	    		    	    	 		isr.place_id,
	    		    	    	 		MIN(isr.dt) min_place_dt
	    		    	    	 FROM	Warehouse.InventoryShkRM isr
	    		    	    	 GROUP BY
	    		    	    	 	isr.inventory_id,
	    		    	    	 	isr.place_id)v
	    			ON	isp.inventory_id = v.inventory_id
	    			AND	v.place_id = isp.place_id
	    WHERE	isp.inventory_id = @inventory_id
	    		AND	insr.shkrm_id IS NULL
	    		AND	smop.dt < v.min_place_dt
	    		AND	NOT EXISTS(
	    		   		SELECT	1
	    		   		FROM	Warehouse.InventoryLostShkRM ilsr
	    		   		WHERE	ilsr.shkrm_id = smop.shkrm_id
	    		   	)
	END
	
	SELECT	@lost_sum = SUM(lt.amount)
	FROM	@lost_tab lt
	
	BEGIN TRY
		BEGIN TRANSACTION 	
		IF @only_data = 0
		BEGIN
		    UPDATE	Warehouse.Inventory
		    SET 	close_dt = @dt,
		    		close_employee_id = @employee_id,
		    		lost_sum = ISNULL(@lost_sum, 0)
		    WHERE	inventory_id = @inventory_id
		    		AND	close_dt IS NULL
		    
		    INSERT INTO Warehouse.InventoryLostShkRM
		    	(
		    		inventory_id,
		    		shkrm_id,
		    		place_id,
		    		okei_id,
		    		qty,
		    		stor_unit_residues_okei_id,
		    		stor_unit_residues_qty,
		    		amount,
		    		employee_id,
		    		dt
		    	)
		    SELECT	@inventory_id,
		    		lt.shkrm_id,
		    		lt.place_id,
		    		lt.okei_id,
		    		lt.qty,
		    		lt.stor_unit_residues_okei_id,
		    		lt.stor_unit_residues_qty,
		    		lt.amount,
		    		@employee_id,
		    		@dt
		    FROM	@lost_tab lt
		    
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
			WHERE	EXISTS (
		     			SELECT	1
		     			FROM	@lost_tab t
		     			WHERE	t.shkrm_id = s.shkrm_id
		     		)
		END
		
		
		
		COMMIT TRANSACTION
		
		SELECT	isr.shkrm_id,
				isr.amount     amount,
				rmt.rmt_name,
				a.art_name,
				isr.okei_id,
				o.symbol       okei_symbol,
				isr.qty,
				smsd.state_name,
				sms.state_id,
				sp.place_name + '(' + os.office_name + ')' place_name
		FROM	@lost_tab isr   
				INNER JOIN	Warehouse.SHKRawMaterialInfo smi
					ON	smi.shkrm_id = isr.shkrm_id   
				INNER JOIN	Material.RawMaterialType rmt
					ON	rmt.rmt_id = smi.rmt_id   
				INNER JOIN	Material.Article a
					ON	a.art_id = smi.art_id   
				INNER JOIN	Qualifiers.OKEI o
					ON	o.okei_id = isr.okei_id   
				LEFT JOIN	Warehouse.SHKRawMaterialState sms   
				INNER JOIN	Warehouse.SHKRawMaterialStateDict smsd
					ON	smsd.state_id = sms.state_id
					ON	sms.shkrm_id = isr.shkrm_id   
				LEFT JOIN	Warehouse.SHKRawMaterialOnPlace smop   
				INNER JOIN	Warehouse.StoragePlace sp   
				INNER JOIN	Warehouse.ZoneOfResponse zor   
				INNER JOIN	Settings.OfficeSetting os
					ON	os.office_id = zor.office_id
					ON	zor.zor_id = sp.zor_id
					ON	sp.place_id = smop.place_id
					ON	smop.shkrm_id = isr.shkrm_id   
				INNER JOIN	Warehouse.SHKRawMaterialAmount sma
					ON	sma.shkrm_id = isr.shkrm_id
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