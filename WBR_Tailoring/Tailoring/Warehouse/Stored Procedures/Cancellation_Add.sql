CREATE PROCEDURE [Warehouse].[Cancellation_Add]
	@employee_id INT,
	@office_id INT,
	@cancellation_year SMALLINT,
	@cancellation_month TINYINT
AS
	SET NOCOUNT ON
	
	DECLARE @dt DATETIME2(0) = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	
	IF @cancellation_month < 1
	   OR @cancellation_month > 12
	BEGIN
	    RAISERROR('Некорректный месяц %d', 16, 1, @cancellation_month)
	    RETURN
	END
	
	IF @cancellation_year < 2015
	BEGIN
	    RAISERROR('Некорректный год %d', 16, 1, @cancellation_year)
	    RETURN
	END
	
	IF NOT EXISTS (
	   	SELECT	1
	   	FROM	Settings.OfficeSetting os
	   	WHERE	os.office_id = @office_id
	   )
	BEGIN
	    RAISERROR('Офиса с кодом %d не существует.', 16, 1, @office_id)
	    RETURN
	END
	
	IF EXISTS (
	   	SELECT	1
	   	FROM	Warehouse.Cancellation c
	   	WHERE	c.office_id = @office_id
	   			AND	c.cancellation_year = @cancellation_year
	   			AND	c.cancellation_month = @cancellation_month
	   )
	BEGIN
	    RAISERROR('Документ на этот период уже существует', 16, 1)
	    RETURN
	END
	
	BEGIN TRY
		INSERT INTO Warehouse.Cancellation
		  (
		    create_dt,
		    create_employee_id,
		    office_id,
		    cancellation_year,
		    cancellation_month
		  )OUTPUT	INSERTED.cancellation_id,
		   		INSERTED.create_employee_id,
		   		INSERTED.office_id,
		   		INSERTED.cancellation_year,
		   		INSERTED.cancellation_month
		VALUES
		  (
		    @dt,
		    @employee_id,
		    @office_id,
		    @cancellation_year,
		    @cancellation_month
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