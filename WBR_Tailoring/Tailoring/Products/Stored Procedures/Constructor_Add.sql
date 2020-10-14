CREATE PROCEDURE [Products].[Constructor_Add]
	@constructor_employee_id INT,
	@employee_id INT
AS
	SET NOCOUNT ON
	
	DECLARE @dt dbo.SECONDSTIME = GETDATE()
	
	BEGIN TRY
		INSERT INTO Products.Constructor
			(
				constructor_employee_id,
				dt,
				employee_id
			)
		SELECT	@constructor_employee_id     constructor_employee_id,
				@dt                          dt,
				@employee_id                 employee_id
		WHERE	NOT EXISTS(
		     		SELECT	1
		     		FROM	Products.Constructor c
		     		WHERE	c.constructor_employee_id = @constructor_employee_id
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