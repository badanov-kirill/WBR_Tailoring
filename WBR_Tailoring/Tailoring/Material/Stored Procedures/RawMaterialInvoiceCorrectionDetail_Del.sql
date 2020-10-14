CREATE PROCEDURE [Material].[RawMaterialInvoiceCorrectionDetail_Del]
	@rmicd_id INT,
	@employee_id INT
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @dt DATETIME2(0) = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	DECLARE @proc_id INT
	EXECUTE @proc_id = History.ProcId_GetByName @procid = @@PROCID
	DECLARE @shkrm_id INT
	DECLARE @place_id INT = 1067
	DECLARE @shkrm_state_dst INT = 3
	DECLARE @amount DECIMAL(19, 8)
	DECLARE @rmic_id INT
	
	SELECT	@error_text = CASE 
	      	                   WHEN rmicd.rmicd_id IS NULL THEN 'Детали документа возврата с номером ' + CAST(v.rmicd_id AS VARCHAR(10)) + ' не существует'
	      	                   WHEN rmic.close_dt IS NOT NULL THEN 'Документ закрыт'
	      	                   WHEN smai.shkrm_id IS NULL THEN 'ШК списан, откатить нельзя'
	      	                   ELSE NULL
	      	              END,
			@shkrm_id     = rmicd.shkrm_id,
			@amount       = rmicd.amount,
			@rmic_id      = rmicd.rmic_id
	FROM	(VALUES(@rmicd_id))v(rmicd_id)   
			LEFT JOIN	Material.RawMaterialInvoiceCorrectionDetail rmicd   
			INNER JOIN	Material.RawMaterialInvoiceCorrection rmic
				ON	rmic.rmic_id = rmicd.rmic_id
				ON	rmicd.rmicd_id = v.rmicd_id   
			LEFT JOIN	Warehouse.SHKRawMaterialActualInfo smai
				ON	smai.shkrm_id = rmicd.shkrm_id
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	BEGIN TRY
		BEGIN TRANSACTION	
		
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
		WHERE	s.shkrm_id = @shkrm_id
		     	
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
		
		UPDATE	Material.RawMaterialInvoiceCorrection
		SET 	amount_shk = amount_shk - @amount
		WHERE	rmic_id = @rmic_id
		
		DELETE	rmicd
		FROM	Material.RawMaterialInvoiceCorrectionDetail rmicd
		WHERE	rmicd.rmicd_id = @rmicd_id
		
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
		WITH LOG;
	END CATCH
GO	