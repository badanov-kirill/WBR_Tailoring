CREATE PROCEDURE [Planing].[PlanShipping_Add]
	@src_office_id INT,
	@dst_office_id INT,
	@plan_dt DATE,
	@employee_id INT,
	@permissible_weight DECIMAL(3,1) 
AS
	SET NOCOUNT ON
	
	DECLARE @dt DATETIME2(0) = GETDATE()
	
	IF NOT EXISTS (
	   	SELECT	1
	   	FROM	Settings.OfficeSetting os
	   	WHERE	os.office_id = @src_office_id
	   )
	BEGIN
	    RAISERROR('Офиса с кодом %d не существует', 16, 1, @src_office_id)
	    RETURN
	END
	
	IF NOT EXISTS (
	   	SELECT	1
	   	FROM	Settings.OfficeSetting os
	   	WHERE	os.office_id = @src_office_id
	   )
	BEGIN
	    RAISERROR('Офиса с кодом %d не существует', 16, 1, @src_office_id)
	    RETURN
	END
	
	IF @plan_dt < @dt
	BEGIN
	    RAISERROR('Нельзя создавать плановую отгрузку на прошедшее число', 16, 1)
	    RETURN
	END
	
	BEGIN TRY
	
	INSERT INTO Planing.PlanShipping
	(
		employee_id,
		dt,
		src_office_id,
		dst_office_id,
		plan_dt,
		permissible_weight
	)
	VALUES
	(
		@employee_id,
		@dt,
		@src_office_id,
		@dst_office_id,
		@plan_dt,
		@permissible_weight
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