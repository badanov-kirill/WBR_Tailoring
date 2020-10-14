CREATE PROCEDURE [Warehouse].[SHKRawMaterial_LostInvent]
	@shkrm_id INT,
	@employee_id INT
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @dt dbo.SECONDSTIME = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	DECLARE @shkrm_state_dst INT = 18
	DECLARE @proc_id INT
	
	EXECUTE @proc_id = History.ProcId_GetByName @procid = @@PROCID
	
	SELECT	@error_text = CASE 
	      	                   WHEN sm.shkrm_id IS NULL THEN 'Штрихкода ' + CAST(v.shkrm_id AS VARCHAR(10)) + ' не существует.'
	      	                   WHEN smai.shkrm_id IS NULL AND sm.shkrm_id IS NOT NULL THEN 'Штрихкод ' + CAST(v.shkrm_id AS VARCHAR(10)) +
	      	                        ' не описан, перед раскладкой необходимо описать шк.'
	      	                   WHEN sms.shkrm_id IS NULL AND smai.shkrm_id IS NOT NULL THEN 'У штрихкода ' + CAST(v.shkrm_id AS VARCHAR(10)) +
	      	                        ' нет статуса, операции со штрихкодом запрещены.'
	      	                   ELSE NULL
	      	              END
	FROM	(VALUES(@shkrm_id))v(shkrm_id)   
			LEFT JOIN	Warehouse.SHKRawMaterial sm  
				ON sm.shkrm_id = v.shkrm_id   
			LEFT JOIN	Warehouse.SHKRawMaterialActualInfo smai
				ON	smai.shkrm_id = v.shkrm_id   
			LEFT JOIN	Warehouse.SHKRawMaterialState sms
				ON	sms.shkrm_id = v.shkrm_id
	
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
		
		RAISERROR('Ошибка %d в строке %d  %s', @esev, @estate, @ErrNum, @Line, @Mess) 
		WITH LOG;
	END CATCH 