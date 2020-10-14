CREATE PROCEDURE [Warehouse].[SHKRawMaterial_Del]
	@shkrm_id INT,
	@employee_id INT
AS
	
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @dt dbo.SECONDSTIME = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	DECLARE @with_log BIT = 1
	DECLARE @proc_id INT
	DECLARE @shkrm_state_accepted INT = 1
	DECLARE @rmid_id INT
	
	EXECUTE @proc_id = History.ProcId_GetByName @procid = @@PROCID
	
	
	SELECT	@error_text = CASE 
	      	                   WHEN smai.shkrm_id IS NULL THEN 'Штрихкод ' + CAST(v.shkrm_id AS VARCHAR(10)) + ' не описан, возможно он уже удален.'
	      	                   WHEN sms.shkrm_id IS NULL THEN 'У штрихкода ' + CAST(v.shkrm_id AS VARCHAR(10)) +
	      	                        ' нет статуса, операции со штрихкодом запрещены. Обратитесь к руководителю.'
	      	                   WHEN sms.state_id NOT IN (@shkrm_state_accepted, 3) THEN 'Штрихкод ' + CAST(v.shkrm_id AS VARCHAR(10)) +
	      	                        ' в статусе ' + smsd.state_name + ', удалять нельзя.'
	      	                   WHEN rmid.rmid_id IS NULL THEN 'Штрихкод ' + CAST(v.shkrm_id AS VARCHAR(10)) + ' отсутствует в поступлении.'
	      	                   WHEN rmi.rmis_id >= 7 THEN 'Документ поступления закрыт менеджером. Удалять ШК нельзя'
	      	                   ELSE NULL
	      	              END,
			@rmid_id = rmid.rmid_id
	FROM	(VALUES(@shkrm_id))v(shkrm_id)   
			LEFT JOIN	Warehouse.SHKRawMaterialInfo smai   
			LEFT JOIN	Warehouse.SHKRawMaterialState sms   
			INNER JOIN	Warehouse.SHKRawMaterialStateDict smsd
				ON	smsd.state_id = sms.state_id
				ON	sms.shkrm_id = smai.shkrm_id
				ON	smai.shkrm_id = v.shkrm_id   
			LEFT JOIN	Material.RawMaterialIncomeDetail rmid
				ON	rmid.shkrm_id = smai.shkrm_id
				AND	smai.doc_id = rmid.doc_id
				AND	smai.doc_type_id = rmid.doc_type_id
			LEFT JOIN Material.RawMaterialIncome rmi
				ON rmi.doc_id = rmid.doc_id
				AND rmi.doc_type_id = rmid.doc_type_id
	
	
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
		
		DELETE	
		FROM	Suppliers.RawMaterialRefundShkDetail
		WHERE	rmid_id = @rmid_id
		
		DELETE	
		FROM	Material.RawMaterialIncomeOrderRelationDetail
		WHERE	rmid_id = @rmid_id
		
		DELETE	
		FROM	Material.RawMaterialIncomeOrderReservRelationDetail
		WHERE	rmid_id = @rmid_id
		
		DELETE	
		FROM	Material.RawMaterialInvoiceRelationDetail
		WHERE	rmid_id = @rmid_id
		
		DELETE	
		FROM	Material.RawMaterialIncomeExpenseRelationDetail
		WHERE	rmid_id = @rmid_id
		
		DELETE	
		FROM	Material.RawMaterialIncomeDetail
		WHERE	rmid_id = @rmid_id
		
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
		
		DELETE	
		FROM	Material.RawMaterialExchange
		WHERE	rmid_id = @rmid_id
		
		DELETE	
		FROM	Material.RawMaterialReturn
		WHERE	rmid_id = @rmid_id
		
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