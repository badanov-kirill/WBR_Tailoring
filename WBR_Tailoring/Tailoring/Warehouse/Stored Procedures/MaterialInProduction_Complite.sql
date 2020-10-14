CREATE PROCEDURE [Warehouse].[MaterialInProduction_Complite]
	@mip_id INT,
	@employee_id INT
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @dt dbo.SECONDSTIME = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	DECLARE @with_log BIT = 1
	DECLARE @proc_id INT
	DECLARE @shk_tab TABLE(shkrm_id INT PRIMARY KEY CLUSTERED)
	
	EXECUTE @proc_id = History.ProcId_GetByName @procid = @@PROCID
	
	SELECT	@error_text = CASE 
	      	                   WHEN mip.mip_id IS NULL THEN 'Документа с номером ' + CAST(v.mip_id AS VARCHAR(10)) + ' не существует.'
	      	                   WHEN mip.complite_dt IS NOT NULL THEN 'Документа с номером ' + CAST(v.mip_id AS VARCHAR(10)) + ' уже закрыт.'
	      	                   ELSE NULL
	      	              END
	FROM	(VALUES(@mip_id))v(mip_id)   
			LEFT JOIN	Warehouse.MaterialInProduction mip
				ON	mip.mip_id = v.mip_id
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	BEGIN TRY
		BEGIN TRANSACTION
		
		UPDATE	Warehouse.MaterialInProduction
		SET 	complite_dt = @dt,
				complite_employee_id = @employee_id
		WHERE	mip_id = @mip_id
				AND	complite_dt IS NULL
		
		IF @@ROWCOUNT = 0
		BEGIN
		    SET @with_log = 0
		    RAISERROR('Документа с номером %d уже закрыт.', 16, 1, @mip_id);
		    RETURN
		END 
		;
		
		UPDATE	Warehouse.MaterialInProductionDetailShk
		SET 	return_qty = 0,
				return_dt = @dt,
				return_employee_id = @employee_id,
				return_recive_employee_id = @employee_id
				OUTPUT	INSERTED.shkrm_id
				INTO	@shk_tab (
						shkrm_id
					)
		WHERE	mip_id = @mip_id
				AND	return_dt IS NULL
		
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
		WHERE	EXISTS(
		     		SELECT	1
		     		FROM	@shk_tab t
		     		WHERE	t.shkrm_id = shkrm_id
		     	)
		
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
		WHERE	EXISTS(
		     		SELECT	1
		     		FROM	@shk_tab t
		     		WHERE	t.shkrm_id = shkrm_id
		     	)
		
		
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
		WHERE	EXISTS(
		     		SELECT	1
		     		FROM	@shk_tab t
		     		WHERE	t.shkrm_id = shkrm_id
		     	)
		
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
		WHERE	EXISTS(
		     		SELECT	1
		     		FROM	@shk_tab t
		     		WHERE	t.shkrm_id = shkrm_id
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