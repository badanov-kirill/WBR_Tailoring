CREATE PROCEDURE [Warehouse].[SHKRawMaterialStateGraph_Add]
	@state_src_id INT,
	@state_dst_id INT,
	@employee_id INT
AS
	SET NOCOUNT ON
	DECLARE @dt dbo.SECONDSTIME = GETDATE()
	
	IF NOT EXISTS (
	   	SELECT	1
	   	FROM	Warehouse.SHKRawMaterialStateDict smsd
	   	WHERE	smsd.state_id = @state_src_id
	   )
	BEGIN
	    RAISERROR('Статуса источника с кодом %d не существует', 16, 1, @state_src_id)
	    RETURN
	END
	
	IF NOT EXISTS (
	   	SELECT	1
	   	FROM	Warehouse.SHKRawMaterialStateDict smsd
	   	WHERE	smsd.state_id = @state_dst_id
	   )
	BEGIN
	    RAISERROR('Статуса приемника с кодом %d не существует', 16, 1, @state_dst_id)
	    RETURN
	END
	
	IF EXISTS (
	   	SELECT	1
	   	FROM	Warehouse.SHKRawMaterialStateGraph smsg
	   	WHERE	smsg.state_src_id = @state_src_id
	   			AND	smsg.state_dst_id = @state_dst_id
	   )
	BEGIN
	    RAISERROR('Такой переход уже существует', 16, 1)
	    RETURN
	END
	
	BEGIN TRY
		INSERT INTO Warehouse.SHKRawMaterialStateGraph
			(
				state_src_id,
				state_dst_id,
				dt,
				employee_id
			)OUTPUT	INSERTED.state_src_id,
			 		INSERTED.state_dst_id,
			 		INSERTED.dt,
			 		INSERTED.employee_id,
			 		0
			 INTO	History.SHKRawMaterialStateGraph (
			 		state_src_id,
			 		state_dst_id,
			 		dt,
			 		employee_id,
			 		is_deleted
			 	)
		VALUES
			(
				@state_src_id,
				@state_dst_id,
				@dt,
				@employee_id
			)
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