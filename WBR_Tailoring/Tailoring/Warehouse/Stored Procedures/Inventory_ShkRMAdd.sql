CREATE PROCEDURE [Warehouse].[Inventory_ShkRMAdd]
	@inventory_id INT,
	@shkrm_id INT,
	@place_id INT,
	@employee_id INT
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @dt dbo.SECONDSTIME = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	DECLARE @inventory_type TINYINT
	
	SELECT	@error_text = CASE 
	      	                   WHEN i.inventory_id IS NULL THEN 'Инвентаризации с кодом ' + CAST(v.inventory_id AS VARCHAR(10)) + ' не существует'
	      	                   WHEN i.close_dt IS NOT NULL THEN 'Инвентаризация № ' + CAST(v.inventory_id AS VARCHAR(10)) +
	      	                        ' уже закрыта, инвентаризировать в неё нельзя.'
	      	                   ELSE NULL
	      	              END,
			@inventory_type = i.it_id
	FROM	(VALUES(@inventory_id))v(inventory_id)   
			LEFT JOIN	Warehouse.Inventory i
				ON	i.inventory_id = v.inventory_id
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	DECLARE @shkrm_state_dst INT = 3
	DECLARE @proc_id INT
	DECLARE @rmt_name VARCHAR(100)
	DECLARE @color_name VARCHAR(50)
	DECLARE @art_name VARCHAR(12)
	DECLARE @qty DECIMAL(9, 3)
	DECLARE @okei_symbol VARCHAR(15)
	DECLARE @frame_width SMALLINT
	DECLARE @okei_id INT
	DECLARE @stor_unit_residues_okei_id INT
	DECLARE @stor_unit_residues_qty DECIMAL(9, 3)
	DECLARE @place_name VARCHAR(50)
	
	
	EXECUTE @proc_id = History.ProcId_GetByName @procid = @@PROCID
	
	SELECT	@error_text = CASE 
	      	                   WHEN sm.shkrm_id IS NULL THEN 'Штрихкода ' + CAST(v.shkrm_id AS VARCHAR(10)) + ' не существует.'
	      	                   ELSE NULL
	      	              END,
			@rmt_name                       = rmt.rmt_name,
			@color_name                     = cc.color_name,
			@art_name                       = a.art_name,
			@okei_symbol                    = o.symbol,
			@qty                            = smai.qty,
			@frame_width                    = smai.frame_width,
			@okei_id                        = smai.okei_id,
			@stor_unit_residues_okei_id     = smai.stor_unit_residues_okei_id,
			@stor_unit_residues_qty         = smai.stor_unit_residues_qty
	FROM	(VALUES(@shkrm_id))v(shkrm_id)   
			LEFT JOIN	Warehouse.SHKRawMaterial sm
				ON	sm.shkrm_id = v.shkrm_id   
			LEFT JOIN	Warehouse.SHKRawMaterialActualInfo smai   
			INNER JOIN	Material.RawMaterialType rmt
				ON	rmt.rmt_id = smai.rmt_id   
			INNER JOIN	Material.ClothColor cc
				ON	cc.color_id = smai.color_id   
			INNER JOIN	Material.Article a
				ON	a.art_id = smai.art_id   
			INNER JOIN	Qualifiers.OKEI o
				ON	o.okei_id = smai.okei_id
				ON	smai.shkrm_id = v.shkrm_id
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	SELECT	@error_text = CASE 
	      	                   WHEN sp.place_id IS NULL THEN 'Места хранения с кодом ' + CAST(v.place_id AS VARCHAR(10)) + ' не существует'
	      	                   WHEN sp.is_deleted = 1 THEN 'Место хранения ' + sp.place_name + ' удалено.'
	      	                   ELSE NULL
	      	              END,
			@place_name = sp.place_name
	FROM	(VALUES(@place_id))v(place_id)   
			LEFT JOIN	Warehouse.StoragePlace sp
				ON	sp.place_id = v.place_id 
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	BEGIN TRY
		BEGIN TRANSACTION 
		
		;WITH cte_target AS
		(
			SELECT	isr.is_id,
					isr.inventory_id,
					isr.shkrm_id,
					isr.place_id,
					isr.okei_id,
					isr.qty,
					isr.stor_unit_residues_okei_id,
					isr.stor_unit_residues_qty,
					isr.employee_id,
					isr.dt
			FROM	Warehouse.InventoryShkRM isr
			WHERE	isr.inventory_id = @inventory_id
					AND	isr.shkrm_id = @shkrm_id
		) 
		MERGE cte_target t
		USING (
		      	SELECT	@inventory_id       inventory_id,
		      			@shkrm_id           shkrm_id,
		      			@place_id           place_id,
		      			ISNULL(@okei_id, 796) okei_id,
		      			ISNULL(@qty, 0)     qty,
		      			ISNULL(@stor_unit_residues_okei_id, 796) stor_unit_residues_okei_id,
		      			ISNULL(@stor_unit_residues_qty, 0) stor_unit_residues_qty,
		      			@employee_id        employee_id,
		      			@dt                 dt
		      ) s
				ON s.inventory_id = t.inventory_id
				AND s.shkrm_id = t.shkrm_id
		WHEN MATCHED THEN 
		     UPDATE	
		     SET 	place_id        = s.place_id,
		     		okei_id         = s.okei_id,
		     		qty             = s.qty,
		     		stor_unit_residues_okei_id = s.stor_unit_residues_okei_id,
		     		stor_unit_residues_qty = s.stor_unit_residues_qty,
		     		employee_id     = s.employee_id,
		     		dt              = s.dt
		WHEN NOT MATCHED THEN 
		     INSERT
		     	(
		     		inventory_id,
		     		shkrm_id,
		     		place_id,
		     		okei_id,
		     		qty,
		     		stor_unit_residues_okei_id,
		     		stor_unit_residues_qty,
		     		employee_id,
		     		dt
		     	)
		     VALUES
		     	(
		     		s.inventory_id,
		     		s.shkrm_id,
		     		s.place_id,
		     		s.okei_id,
		     		s.qty,
		     		s.stor_unit_residues_okei_id,
		     		s.stor_unit_residues_qty,
		     		s.employee_id,
		     		s.dt
		     	);    	
		
		IF @inventory_type = 1
		BEGIN
		    INSERT INTO Warehouse.InventoryStoragePlace
		    	(
		    		inventory_id,
		    		place_id
		    	)
		    SELECT	@inventory_id,
		    		@place_id
		    WHERE	NOT EXISTS (
		         		SELECT	1
		         		FROM	Warehouse.InventoryStoragePlace isp
		         		WHERE	isp.inventory_id = @inventory_id
		         				AND	isp.place_id = @place_id
		         	)
		END
		
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
		WHERE	shkrm_id = @shkrm_id
				AND	(
				   		EXISTS (
				   			SELECT	1
				   			FROM	Warehouse.SHKRawMaterialStateGraph smsg
				   			WHERE	smsg.state_src_id = s.state_id
				   					AND	smsg.state_dst_id = @shkrm_state_dst
				   		)
				   	)   	
		
		
		IF @@ROWCOUNT != 0
		BEGIN
		    ;
		    MERGE Warehouse.SHKRawMaterialOnPlace t
		    USING (
		          	SELECT	@shkrm_id        shkrm_id,
		          			@place_id        place_id,
		          			@dt              dt,
		          			@employee_id     employee_id
		          ) s
		    		ON s.shkrm_id = t.shkrm_id
		    WHEN MATCHED THEN 
		         UPDATE	
		         SET 	shkrm_id        = s.shkrm_id,
		         		place_id        = s.place_id,
		         		dt              = s.dt,
		         		employee_id     = s.employee_id
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
		         		s.place_id,
		         		s.dt,
		         		s.employee_id
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
		
		COMMIT TRANSACTION
		
		SELECT	ISNULL(@rmt_name, '')       rmt_name,
				ISNULL(@color_name, '')     color_name,
				ISNULL(@art_name, '')       art_name,
				ISNULL(@okei_symbol, 'шт') okei_symbol,
				ISNULL(@frame_width, 0)     frame_width,
				ISNULL(@okei_id, 796)       okei_id,
				ISNULL(@qty, 0)             qty,
				ISNULL(@stor_unit_residues_okei_id, 796) stor_unit_residues_okei_id,
				ISNULL(@stor_unit_residues_qty, 0) stor_unit_residues_qty,
				@place_name                 place_name
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