CREATE PROCEDURE [Warehouse].[SHKRawMaterialStateDict_Set]
	@state_id INT,
	@state_name VARCHAR(50),
	@state_descr VARCHAR(500),
	@employee_id INT
AS
	SET NOCOUNT ON
	DECLARE @dt dbo.SECONDSTIME = GETDATE()
	
	IF EXISTS (
	   	SELECT	1
	   	FROM	Warehouse.SHKRawMaterialStateDict smsd
	   	WHERE	smsd.state_name = @state_name
	   			AND	smsd.state_id != @state_id
	   )
	BEGIN
	    RAISERROR('Такое наименование уже используется', 16, 1)
	    RETURN
	END
	
	BEGIN TRY
		;
		MERGE Warehouse.SHKRawMaterialStateDict t
		USING (
		      	SELECT	@state_id        state_id,
		      			@state_name      state_name,
		      			@state_descr     state_descr,
		      			@dt              dt,
		      			@employee_id     employee_id
		      ) s
				ON s.state_id = t.state_id
		WHEN  MATCHED  THEN 
		     UPDATE	
		     SET 	state_name      = s.state_name,
		     		state_descr     = s.state_descr,
		     		dt              = s.dt,
		     		employee_id     = s.employee_id
		WHEN NOT MATCHED  THEN 
		     INSERT
		     	(
		     		state_id,
		     		state_name,
		     		state_descr,
		     		dt,
		     		employee_id
		     	)
		     VALUES
		     	(
		     		s.state_id,
		     		s.state_name,
		     		s.state_descr,
		     		s.dt,
		     		s.employee_id
		     	)
		     OUTPUT	INSERTED.state_id,
		     		INSERTED.state_name,
		     		INSERTED.state_descr,
		     		INSERTED.dt,
		     		INSERTED.employee_id
		     INTO	History.SHKRawMaterialStateDict (
		     		state_id,
		     		state_name,
		     		state_descr,
		     		dt,
		     		employee_id
		     	);
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