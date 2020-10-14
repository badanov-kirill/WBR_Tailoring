CREATE PROCEDURE [Logistics].[Shipping_Add]
	@employee_id INT
AS
	SET NOCOUNT ON
	DECLARE @office_id INT
	DECLARE @office_name VARCHAR(50)
	DECLARE @dt dbo.SECONDSTIME = GETDATE()
	
	SELECT	@office_id = ts.office_id,
			@office_name = os.office_name
	FROM	Settings.EmployeeTransferSetting ets   
			INNER JOIN	Settings.TransferSetting ts
				ON	ts.ts_id = ets.ts_id   
			INNER JOIN	Settings.OfficeSetting os
				ON	os.office_id = ts.office_id
	WHERE	ets.employee_id = @employee_id
	
	IF @office_id IS NULL
	BEGIN
	    RAISERROR('На сотрудника не установлена настройка логистика. Обратитесь к руководителю', 16, 1)
	    RETURN
	END
	
	IF EXISTS(
	   	SELECT	1
	   	FROM	Logistics.Shipping s
	   	WHERE	s.src_office_id = @office_id
	   			AND	s.close_dt IS NULL
	   			AND	s.is_deleted = 0
	   )
	BEGIN
	    RAISERROR('Уже есть неотправленная отгрузка из этого офиса. Нельзя собирать две отгрузки одновременно', 16, 1)
	    RETURN
	END
	
	BEGIN TRY
		INSERT INTO Logistics.Shipping
		  (
		    employee_id,
		    dt,
		    create_employee_id,
		    create_dt,
		    src_office_id,
		    is_deleted
		  )OUTPUT	INSERTED.shipping_id,
		   		INSERTED.src_office_id,
		   		@office_name src_office_name,
		   		CAST(@dt AS DATETIME) create_dt,
		   		CAST(CAST(INSERTED.rv AS BIGINT) AS VARCHAR(19)) rv_bigint
		VALUES
		  (
		    @employee_id,
		    @dt,
		    @employee_id,
		    @dt,
		    @office_id,
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