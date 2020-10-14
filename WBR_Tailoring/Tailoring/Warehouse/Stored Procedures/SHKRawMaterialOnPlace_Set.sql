CREATE PROCEDURE [Warehouse].[SHKRawMaterialOnPlace_Set]
	@shkrm_id INT,
	@place_id INT,
	@employee_id INT
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @dt dbo.SECONDSTIME = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	DECLARE @shkrm_state_dst INT = 3
	DECLARE @proc_id INT
	DECLARE @rmt_name VARCHAR(100)
	DECLARE @color_name VARCHAR(50)
	DECLARE @art_name VARCHAR(12)
	DECLARE @qty DECIMAL(9, 3)
	DECLARE @okei_symbol VARCHAR(15)
	DECLARE @frame_width SMALLINT
		
	EXECUTE @proc_id = History.ProcId_GetByName @procid = @@PROCID
	
	SELECT	@error_text = CASE 
	      	                   WHEN sm.shkrm_id IS NULL THEN 'Штрихкода ' + CAST(v.shkrm_id AS VARCHAR(10)) + ' не существует.'
	      	                   WHEN smai.shkrm_id IS NULL THEN 'Штрихкод ' + CAST(v.shkrm_id AS VARCHAR(10)) +
	      	                        ' не описан, перед раскладкой необходимо описать шк.'
	      	                   WHEN sms.shkrm_id IS NULL THEN 'У штрихкода ' + CAST(v.shkrm_id AS VARCHAR(10)) +
	      	                        ' нет статуса, операции со штрихкодом запрещены. Обратитесь к руководителю'
	      	                   WHEN smsg.state_src_id IS NULL THEN 
	      	                        'Штрихкод ' + CAST(v.shkrm_id AS VARCHAR(10)) +
	      	                        ' в статусе ' + smsd.state_name +
	      	                        '. Переход в статус ' + smsd2.state_name + ' запрещен.'
	      	                   ELSE NULL
	      	              END,
			@rmt_name = rmt.rmt_name,
			@color_name = cc.color_name,
			@art_name = a.art_name,
			@okei_symbol = o.symbol,
			@qty = smai.qty,
			@frame_width = smai.frame_width
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
	      	              END
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
		
		UPDATE	s
		SET 	state_id =  @shkrm_state_dst,
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
		
		IF @@ROWCOUNT = 0
		BEGIN
		    RAISERROR('Операция со штрихкодом %d запрещена', 16, 1, @shkrm_id);
		    RETURN
		END 
		
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
		
		
		COMMIT TRANSACTION
		
		SELECT	@rmt_name        rmt_name,
				@color_name      color_name,
				@art_name        art_name,
				@okei_symbol     okei_symbol,
				@qty             qty,
				ISNULL(@frame_width, 0)	 frame_width
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