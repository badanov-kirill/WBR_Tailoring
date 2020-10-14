CREATE PROCEDURE [Material].[RawMaterialExchange_Return]
	@shkrm_id INT,
	@employee_id INT
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @dt dbo.SECONDSTIME = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	DECLARE @with_log BIT = 1
	DECLARE @shkrm_state_dst INT = 15
	DECLARE @proc_id INT
	DECLARE @rme_id INT
	
	EXECUTE @proc_id = History.ProcId_GetByName @procid = @@PROCID
	
	SELECT	@error_text = CASE 
	      	                   WHEN sm.shkrm_id IS NULL THEN 'Штрихкода ' + CAST(v.shkrm_id AS VARCHAR(10)) + ' не существует.'
	      	                   WHEN smai.shkrm_id IS NULL THEN 'Штрихкод ' + CAST(v.shkrm_id AS VARCHAR(10)) +
	      	                        ' не описан.'
	      	                   WHEN sms.shkrm_id IS NULL THEN 'У штрихкода ' + CAST(v.shkrm_id AS VARCHAR(10)) +
	      	                        ' нет статуса, операции со штрихкодом запрещены. Обратитесь к руководителю'
	      	                   WHEN smsg.state_src_id IS NULL THEN 'Штрихкод ' + CAST(v.shkrm_id AS VARCHAR(10)) + ' в статусе ' + smsd.state_name +
	      	                        '. Переход в статус ' + smsd2.state_name + ' запрещен.'
	      	                   WHEN rme.change_dt IS NULL AND sma.amount = 0 THEN 'Не распределена стоимость'
	      	                   WHEN rme.shkrm_id IS NULL THEN 'На штрихкода ' + CAST(v.shkrm_id AS VARCHAR(10)) + ' не создан документ обмена.'
	      	                   ELSE NULL
	      	              END,
			@rme_id = rme.rme_id
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
				ON	smai.shkrm_id = v.shkrm_id   
			LEFT JOIN	Material.RawMaterialExchange rme
				ON	rme.shkrm_id = sm.shkrm_id
			LEFT JOIN Warehouse.SHKRawMaterialAmount sma
				ON sma.shkrm_id = sm.shkrm_id
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	BEGIN TRY
		BEGIN TRANSACTION		
		
		UPDATE	Material.RawMaterialExchange
		SET 	return_dt = @dt,
				return_employee_id = @employee_id,
				dt = @dt,
				employee_id = @employee_id
		WHERE	rme_id = @rme_id
		
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