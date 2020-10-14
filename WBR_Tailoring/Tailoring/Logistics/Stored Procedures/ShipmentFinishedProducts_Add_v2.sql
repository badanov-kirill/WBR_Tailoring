CREATE PROCEDURE [Logistics].[ShipmentFinishedProducts_Add_v2]
	@employee_id INT,
	@office_id INT,
	@plan_dt DATE
AS
	SET NOCOUNT ON
	DECLARE @dt DATETIME2(0) = GETDATE()
	
	IF @plan_dt < @dt
	BEGIN
	    RAISERROR('Плановая дата должна быть больше текущей', 16, 1)
	    RETURN
	END
	
	IF NOT EXISTS (SELECT 1 FROM Settings.OfficeSetting os WHERE os.office_id = @office_id )
	BEGIN
	    RAISERROR('Нет офиса с кодом %d', 16, 1, @office_id)
	    RETURN
	END
	
	IF EXISTS(
	   	SELECT	1
	   	FROM	Logistics.ShipmentFinishedProducts s
	   	WHERE	s.src_office_id = @office_id
	   			AND	s.complite_dt IS NULL
	   			AND s.plan_dt = @plan_dt
	   			AND	s.is_deleted = 0
	   )
	BEGIN
	    RAISERROR('Уже есть неотправленная отгрузка из этого офиса с этой план датой.', 16, 1)
	    RETURN
	END
	
	BEGIN TRY
		INSERT INTO Logistics.ShipmentFinishedProducts
			(
				employee_id,
				dt,
				create_employee_id,
				create_dt,
				src_office_id,
				is_deleted,
				plan_dt
			)
		VALUES
			(
				@employee_id,
				@dt,
				@employee_id,
				@dt,
				@office_id,
				0,
				@plan_dt
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