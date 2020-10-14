CREATE PROCEDURE [Logistics].[Driver_Add]
	@driver_name VARCHAR(100),
	@employee_id INT
AS
	SET NOCOUNT ON
	DECLARE @dt dbo.SECONDSTIME = GETDATE()
	
	IF EXISTS(
	   	SELECT	1
	   	FROM	Logistics.Driver d
	   	WHERE	d.driver_name = @driver_name
	   )
	BEGIN
	    RAISERROR('Водитель %s уже существует', 16, 1, @driver_name)
	    RETURN
	END
	
	BEGIN TRY
		INSERT INTO Logistics.Driver
		  (
		    driver_name,
		    dt,
		    employee_id
		  )OUTPUT	INSERTED.driver_id
		VALUES
		  (
		    @driver_name,
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
