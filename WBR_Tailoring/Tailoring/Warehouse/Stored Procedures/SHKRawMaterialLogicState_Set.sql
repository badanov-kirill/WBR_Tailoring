CREATE PROCEDURE [Warehouse].[SHKRawMaterialLogicState_Set]
	@shkrm_tab dbo.List READONLY,
	@employee_id INT,
	@state_id INT
AS
	SET NOCOUNT ON
	DECLARE @dt DATETIME2(0) = GETDATE(),
	        @error_text VARCHAR(MAX)
	
	DECLARE @proc_id INT
	EXECUTE @proc_id = History.ProcId_GetByName @procid = @@PROCID
	
	SELECT	@error_text = 'Складских ШК с кодами '
	      	+
	      	STUFF(
	      		(
	      			SELECT	', ' + CAST(d.id AS VARCHAR(10))
	      			FROM	@shkrm_tab d   
	      					LEFT JOIN	Warehouse.SHKRawMaterialActualInfo smai
	      						ON	smai.shkrm_id = d.id
	      			WHERE	smai.shkrm_id IS NULL
	      			FOR XML	PATH('')
	      		),
	      		1,
	      		2,
	      		''
	      	)
	      	+
	      	' не существует'
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR(@error_text, 16, 1)
	    RETURN
	END
	
	IF @state_id IS NOT NULL AND NOT EXISTS (
	   	SELECT	1
	   	FROM	Warehouse.SHKRawMaterialLogicStateDict smlsd
	   	WHERE	smlsd.state_id = @state_id
	   )
	BEGIN
	    RAISERROR('Статуса с кодом %d не существует', 16, 1, @state_id)
	    RETURN
	END
	
	BEGIN TRY
		IF @state_id IS NULL
		BEGIN
		    DELETE	smls OUTPUT	DELETED.shkrm_id,
		          	     		DELETED.state_id,
		          	     		DELETED.dt,
		          	     		DELETED.employee_id,
		          	     		@proc_id
		          	     INTO	History.SHKRawMaterialLogicState (
		          	     		shkrm_id,
		          	     		state_id,
		          	     		dt,
		          	     		employee_id,
		          	     		proc_id
		          	     	)
		    FROM	Warehouse.SHKRawMaterialLogicState smls   
		    		INNER JOIN	@shkrm_tab t
		    			ON	smls.shkrm_id = t.id
		END
		ELSE
		BEGIN
		    ;
		    WITH cte_target AS (
		    	SELECT	smls.shkrm_id,
		    			smls.state_id,
		    			smls.dt,
		    			smls.employee_id,
		    			smls.rv
		    	FROM	Warehouse.SHKRawMaterialLogicState smls   
		    			INNER JOIN	@shkrm_tab t
		    				ON	smls.shkrm_id = t.id
		    )
		    MERGE cte_target t
		    USING @shkrm_tab s
		    		ON t.shkrm_id = s.id
		    WHEN MATCHED THEN 
		         UPDATE	
		         SET 	state_id        = @state_id,
		         		dt              = @dt,
		         		employee_id     = @employee_id
		    WHEN NOT MATCHED THEN 
		         INSERT
		         	(
		         		shkrm_id,
		         		state_id,
		         		dt,
		         		employee_id
		         	)
		         VALUES
		         	(
		         		s.id,
		         		@state_id,
		         		@dt,
		         		@employee_id
		         	)
		         OUTPUT	INSERTED.shkrm_id,
		         		INSERTED.state_id,
		         		INSERTED.dt,
		         		INSERTED.employee_id,
		         		@proc_id
		         INTO	History.SHKRawMaterialLogicState (
		         		shkrm_id,
		         		state_id,
		         		dt,
		         		employee_id,
		         		proc_id
		         	);
		END;
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