CREATE PROCEDURE [Logistics].[TTN_Add]
	@shipping_id INT,
	@employee_id INT,
	@vehicle_id INT,
	@driver_id INT,
	@src_office_id INT,
	@dst_office_id INT,
	@seal1 VARCHAR(20) = NULL,
	@seal2 VARCHAR(20) = NULL,
	@towed_vehicle_id INT = NULL
AS
	SET NOCOUNT ON
	
	DECLARE @dt dbo.SECONDSTIME = GETDATE()
	
	IF NOT EXISTS (
	   	SELECT	1
	   	FROM	Logistics.Shipping s
	   	WHERE	s.shipping_id = @shipping_id
	   )
	BEGIN
	    RAISERROR('Отгрузки с номером %d не существует', 16, 1, @shipping_id)
	    RETURN
	END
	
	IF NOT EXISTS (
	   	SELECT	1
	   	FROM	Logistics.Vehicle v
	   	WHERE	v.vehicle_id = @vehicle_id
	   )
	BEGIN
	    RAISERROR('Автомобиля с кодом %d не существует', 16, 1, @vehicle_id)
	    RETURN
	END
	
	IF NOT EXISTS (
	   	SELECT	1
	   	FROM	Logistics.Driver d
	   	WHERE	d.driver_id = @driver_id
	   )
	BEGIN
	    RAISERROR('Водителя с кодом %d не существует', 16, 1, @driver_id)
	    RETURN
	END
	
	IF NOT EXISTS (
	   	SELECT	1
	   	FROM	Settings.EmployeeTransferSetting ets   
	   			INNER JOIN	Settings.TransferSetting ts
	   				ON	ts.ts_id = ets.ts_id
	   	WHERE	ets.employee_id = @employee_id
	   			AND	ts.office_id = @src_office_id
	   )
	BEGIN
	    RAISERROR('Вам нельзя отправлять из этого офиса', 16, 1)
	    RETURN
	END
	
	IF NOT EXISTS (
	   	SELECT	1
	   	FROM	Settings.EmployeeTransferSetting ets   
	   			INNER JOIN	Settings.TransferSetting ts
	   				ON	ts.ts_id = ets.ts_id   
	   			INNER JOIN	Settings.TransferSettingOfiice tso
	   				ON	tso.ts_id = ts.ts_id
	   	WHERE	ets.employee_id = @employee_id
	   			AND	tso.office_id = @dst_office_id
	   )
	BEGIN
	    RAISERROR('Вам нельзя отправлять в этот офиса', 16, 1)
	    RETURN
	END	
	
	IF @towed_vehicle_id IS NOT NULL
	   AND NOT EXISTS (
	       	SELECT	1
	       	FROM	Logistics.Vehicle v
	       	WHERE	v.vehicle_id = @towed_vehicle_id
	       )
	BEGIN
	    RAISERROR('Прицепа с кодом %d не существует', 16, 1, @towed_vehicle_id)
	    RETURN
	END
	
	BEGIN TRY
		INSERT INTO Logistics.TTN
		  (
		    shipping_id,
		    src_office_id,
		    dst_office_id,
		    seal1,
		    seal2,
		    employee_id,
		    dt,
		    vehicle_id,
		    driver_id,
		    towed_vehicle_id,
		    is_deleted,
		    create_employee_id,
		    create_dt
		  )OUTPUT	INSERTED.ttn_id,
		   		CAST(@dt AS DATETIME) dt
		VALUES
		  (
		    @shipping_id,
		    @src_office_id,
		    @dst_office_id,
		    @seal1,
		    @seal2,
		    @employee_id,
		    @dt,
		    @vehicle_id,
		    @driver_id,
		    @towed_vehicle_id,
		    0,
		    @employee_id,
		    @dt
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