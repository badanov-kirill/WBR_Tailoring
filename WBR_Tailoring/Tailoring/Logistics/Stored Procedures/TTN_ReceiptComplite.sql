CREATE PROCEDURE [Logistics].[TTN_ReceiptComplite]
	@ttn_id INT,
	@employee_id INT
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @dt dbo.SECONDSTIME = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	DECLARE @shkrm_state_dst INT = 6
	DECLARE @with_log BIT = 1
	DECLARE @place_id INT
	DECLARE @proc_id INT
	
	EXECUTE @proc_id = History.ProcId_GetByName @procid = @@PROCID
	
	SELECT	@error_text = CASE 
	      	                   WHEN t.ttn_id IS NULL THEN 'ТТН с номером ' + CAST(v.ttn_id AS VARCHAR(10)) + ' не существует.'
	      	                   WHEN t.complite_dt IS NOT NULL THEN 'ТТН с номером ' + CAST(v.ttn_id AS VARCHAR(10)) + ' уже закрытка.'
	      	                   WHEN s.complite_dt IS NOT NULL THEN 'Отгрузка № ' + CAST(s.shipping_id AS VARCHAR(10)) + ' уже обработана'
	      	                   WHEN os.office_id IS NULL THEN 'Нет настройки офиса получения'
	      	                   ELSE NULL
	      	              END,
			@place_id = os.buffer_zone_place_id
	FROM	(VALUES(@ttn_id))v(ttn_id)   
			LEFT JOIN	Logistics.TTN t
				ON	t.ttn_id = v.ttn_id   
			LEFT JOIN	Settings.OfficeSetting os
				ON	t.dst_office_id = os.office_id   
			LEFT JOIN	Logistics.Shipping s
				ON	s.shipping_id = t.shipping_id	
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	BEGIN TRY
		BEGIN TRANSACTION
		
		UPDATE	Logistics.TTN
		SET 	complite_employee_id = @employee_id,
				complite_dt = @dt
		WHERE	ttn_id = @ttn_id
				AND	complite_dt IS NULL
		
		IF @@ROWCOUNT = 0
		BEGIN
		    SET @with_log = 0
		    RAISERROR('ТТН с номером %d уже принята', 16, 1, @ttn_id);
		    RETURN
		END 
		
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
		     		FROM	Logistics.TTNDetail td
		     		WHERE	td.ttn_id = @ttn_id
		     				AND	td.shkrm_id = s.shkrm_id
		     				AND	td.complite_dt IS NOT NULL
		     	)
				OR	EXISTS(
				  		SELECT	1
				  		FROM	Logistics.TTNDivergenceAct ta
				  		WHERE	ta.ttn_id = @ttn_id
				  				AND	ta.shkrm_id = s.shkrm_id
				  	) 
		
		;
		MERGE Warehouse.SHKRawMaterialOnPlace t
		USING (
		      	SELECT	td.shkrm_id
		      	FROM	Logistics.TTNDetail td
		      	WHERE	td.ttn_id = @ttn_id
		      			AND	td.complite_dt IS NOT NULL
		      	UNION
		      	SELECT	ta.shkrm_id
		      	FROM	Logistics.TTNDivergenceAct ta
		      	WHERE	ta.ttn_id = @ttn_id
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
		
		INSERT INTO Logistics.TTNDivergenceAct
		  (
		    create_employee_id,
		    create_dt,
		    ttn_id,
		    shkrm_id,
		    rmt_id,
		    art_id,
		    okei_id,
		    divergence_qty,
		    stor_unit_residues_okei_id,
		    stor_unit_residues_qty,
		    nds,
		    gross_mass
		  )
		SELECT	@employee_id,
				@dt,
				@ttn_id,
				t.shkrm_id,
				t.rmt_id,
				t.art_id,
				t.okei_id,
				t.qty,
				t.stor_unit_residues_okei_id,
				t.stor_unit_residues_qty,
				t.nds,
				t.gross_mass
		FROM	Logistics.TTNDetail t
		WHERE	t.ttn_id = @ttn_id
				AND	t.complite_dt IS NULL
				AND	NOT EXISTS(
				   		SELECT	1
				   		FROM	Logistics.TTNDivergenceAct ta
				   		WHERE	ta.ttn_id = @ttn_id
				   				AND	ta.shkrm_id = t.shkrm_id
				   	)
		
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