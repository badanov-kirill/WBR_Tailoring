CREATE PROCEDURE [Logistics].[Shipping_Close]
	@shipping_id INT,
	@employee_id INT
AS
	SET NOCOUNT ON
	DECLARE @dt dbo.SECONDSTIME = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	DECLARE @shkrm_state_dst INT = 5
	DECLARE @with_log BIT = 1
	DECLARE @place_id INT	
	DECLARE @proc_id INT
	
	EXECUTE @proc_id = History.ProcId_GetByName @procid = @@PROCID
	
	SELECT	@error_text = CASE 
	      	                   WHEN v.shipping_id IS NULL THEN 'Отгрузки с номером ' + CAST(v.shipping_id AS VARCHAR(10)) + ' не существует.'
	      	                   WHEN s.close_dt IS NOT NULL THEN 'Отгрузка № ' + CAST(s.shipping_id AS VARCHAR(10)) + ' уже отправлена'
	      	                   WHEN os.office_id IS NULL THEN 'Отсутствует настройка офиса отправки'
	      	                   ELSE NULL
	      	              END,
			@place_id = os.buffer_zone_place_id
	FROM	(VALUES(@shipping_id))v(shipping_id)   
			LEFT JOIN	Logistics.Shipping s
				ON	s.shipping_id = v.shipping_id   
			LEFT JOIN	Settings.OfficeSetting os
				ON	os.office_id = s.src_office_id
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	SET @error_text = (
	    	SELECT	CASE 
	    	      	     WHEN sms.shkrm_id IS NULL THEN 'У штрихкода ' + CAST(td.shkrm_id AS VARCHAR(10)) +
	    	      	          ' нет статуса, операции со штрихкодом запрещены. Обратитесь к руководителю' + CHAR(10)
	    	      	     WHEN sms.state_id = @shkrm_state_dst THEN 'Штрихкод ' + CAST(td.shkrm_id AS VARCHAR(10)) + ' уже отправлен'
	    	      	     WHEN smai.shkrm_id IS NULL THEN 'Штрихкод ' + CAST(td.shkrm_id AS VARCHAR(10)) +
	    	      	          ' не описан.' + CHAR(10)
	    	      	     WHEN smsg.state_src_id IS NULL THEN 'Штрихкод ' + CAST(td.shkrm_id AS VARCHAR(10)) + ' в статусе ' + smsd.state_name +
	    	      	          '. Переход в статус ' + smsd2.state_name + ' запрещен.' + CHAR(10)
	    	      	     ELSE NULL
	    	      	END
	    	FROM	Logistics.Shipping s   
	    			INNER JOIN	Logistics.TTN t
	    				ON	t.shipping_id = s.shipping_id   
	    			INNER JOIN	Logistics.TTNDetail td
	    				ON	td.ttn_id = t.ttn_id   
	    			LEFT JOIN	Warehouse.SHKRawMaterialState sms
	    				ON	sms.shkrm_id = td.shkrm_id   
	    			LEFT JOIN	Warehouse.SHKRawMaterialStateDict smsd
	    				ON	smsd.state_id = sms.state_id   
	    			LEFT JOIN	Warehouse.SHKRawMaterialStateGraph smsg
	    				ON	sms.state_id = smsg.state_src_id
	    				AND	smsg.state_dst_id = @shkrm_state_dst   
	    			INNER JOIN	Warehouse.SHKRawMaterialStateDict smsd2
	    				ON	smsd2.state_id = @shkrm_state_dst   
	    			LEFT JOIN	Warehouse.SHKRawMaterialActualInfo smai
	    				ON	smai.shkrm_id = td.shkrm_id
	    	WHERE	s.shipping_id = @shipping_id
	    			AND	(sms.shkrm_id IS NULL OR sms.state_id = @shkrm_state_dst OR smai.shkrm_id IS NULL OR smsg.state_src_id IS NULL)
	    	FOR XML	PATH('')
	    )
	
	IF @error_text IS NOT NULL
	   AND LEN(@error_text) > 0
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	BEGIN TRY
		BEGIN TRANSACTION
		
		UPDATE	Logistics.Shipping
		SET 	employee_id = @employee_id,
				dt = @dt,
				close_employee_id = @employee_id,
				close_dt = @dt
		WHERE	shipping_id = @shipping_id
				AND	close_dt IS NULL
		
		IF @@ROWCOUNT = 0
		BEGIN
		    SET @with_log = 0
		    RAISERROR('Отгрузка с номером %d уже отправлена', 16, 1, @shipping_id);
		    RETURN
		END 		
		
		UPDATE	psd
		SET 	shipping_dt = @dt
		FROM	Planing.PlanShippingDetail psd
				INNER JOIN	Logistics.TTNDetail t
					ON	t.ttnd_id = psd.ttnd_id
				INNER JOIN	Logistics.TTN ttn
					ON	ttn.ttn_id = t.ttn_id
		WHERE	ttn.shipping_id = @shipping_id		
		
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
		FROM	Logistics.Shipping sh
				INNER JOIN	Logistics.TTN t
					ON	t.shipping_id = sh.shipping_id
				INNER JOIN	Logistics.TTNDetail td
					ON	td.ttn_id = t.ttn_id
				INNER JOIN	Warehouse.SHKRawMaterialState s
					ON	s.shkrm_id = td.shkrm_id
		WHERE	sh.shipping_id = @shipping_id
		     	
		     	MERGE Warehouse.SHKRawMaterialOnPlace t
		     	USING (
		     	      	SELECT	td.shkrm_id
		     	      	FROM	Logistics.Shipping sh   
		     	      			INNER JOIN	Logistics.TTN t
		     	      				ON	t.shipping_id = sh.shipping_id   
		     	      			INNER JOIN	Logistics.TTNDetail td
		     	      				ON	td.ttn_id = t.ttn_id
		     	      	WHERE	sh.shipping_id = @shipping_id
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
		
		COMMIT TRANSACTION
		
		SELECT	CAST(@dt AS DATETIME) dt
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