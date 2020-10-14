CREATE PROCEDURE [Warehouse].[AssemblyList_Add]
	@employee_id INT,
	@workshop_id INT = NULL,
	@shipping_dt DATETIME2(0) = NULL
AS
	SET NOCOUNT ON
	DECLARE @dt dbo.SECONDSTIME = GETDATE()
	
	IF @workshop_id IS NOT NULL
	   AND NOT EXISTS (
	       	SELECT	1
	       	FROM	Warehouse.Workshop w
	       	WHERE	w.workshop_id = @workshop_id
	       )
	BEGIN
	    RAISERROR('Цеха с кодом %d не существует', 16, 1, @workshop_id)
	    RETURN
	END
	
	BEGIN TRY
		INSERT INTO Warehouse.AssemblyList
		  (
		    create_dt,
		    create_employee_id,
		    workshop_id,
		    shipping_dt,
		    dt,
		    employee_id
		  )OUTPUT	INSERTED.al_id,
		   		CAST(INSERTED.create_dt AS DATETIME) create_dt,
		   		INSERTED.workshop_id,
		   		CAST(CAST(INSERTED.rv AS BIGINT) AS VARCHAR(19)) rv_bigint
		VALUES
		  (
		    @dt,
		    @employee_id,
		    @workshop_id,
		    @shipping_dt,
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