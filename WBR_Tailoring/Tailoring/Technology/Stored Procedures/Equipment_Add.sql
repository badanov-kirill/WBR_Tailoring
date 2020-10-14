CREATE PROCEDURE [Technology].[Equipment_Add]
	@equipment_name VARCHAR(50),
	@employee_id INT
AS
	SET NOCOUNT ON
	DECLARE @dt DATETIME2(0) = GETDATE()
	
	IF EXISTS(
	   	SELECT	1
	   	FROM	Technology.Equipment e
	   	WHERE	e.equipment_name = @equipment_name
	   			AND	e.is_deleted = 0
	   )
	BEGIN
	    RAISERROR('Такое наименование %s уже есть', 16, 1, @equipment_name)
	    RETURN
	END
	
	BEGIN TRY
		INSERT INTO Technology.Equipment
		  (
		    equipment_name,
		    dt,
		    employee_id,
		    is_deleted
		  )OUTPUT	INSERTED.equipment_id,
		   		INSERTED.equipment_name,
		   		INSERTED.is_deleted
		VALUES
		  (
		    @equipment_name,
		    @dt,
		    @employee_id,
		    0
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