CREATE PROCEDURE [Manufactory].[WorkshopEquipment_Add]
	@equipment_id INT,
	@article VARCHAR(15) = NULL,
	@serial_num VARCHAR(50) = NULL,
	@stuff_shk_id INT = NULL,
	@comment VARCHAR(200) = NULL,
	@zor_id INT,
	@employee_id INT,
	@work_hour DECIMAL(3,1)
AS
	SET NOCOUNT ON
	
	DECLARE @dt DATETIME2(0) = GETDATE()
	
	IF NOT EXISTS (
	   	SELECT	1
	   	FROM	Technology.Equipment e
	   	WHERE	e.equipment_id = @equipment_id
	   )
	BEGIN
	    RAISERROR('Оборудования с кодом %d не существует', 16, 1)
	    RETURN
	END
	
	IF NOT EXISTS (
	   	SELECT	1
	   	FROM	Warehouse.ZoneOfResponse zor
	   	WHERE	zor.zor_id = @zor_id
	   )
	BEGIN
	    RAISERROR('Зоны ответственности с кодом %d не существует', 16, 1)
	    RETURN
	END
	
	BEGIN TRY
		BEGIN TRANSACTION	
		
		INSERT INTO Manufactory.WorkshopEquipment
			(
				equipment_id,
				article,
				serial_num,
				stuff_shk_id,
				comment,
				zor_id,
				dt,
				employee_id,
				is_deleted,
				work_hour
			)
		VALUES
			(
				@equipment_id,
				@article,
				@serial_num,
				@stuff_shk_id,
				@comment,
				@zor_id,
				@dt,
				@employee_id,
				0,
				@work_hour
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
		
		
		RAISERROR('Ошибка %d в строке %d  %s', @esev, @estate, @ErrNum, @Line, @Mess) WITH LOG;
	END CATCH 