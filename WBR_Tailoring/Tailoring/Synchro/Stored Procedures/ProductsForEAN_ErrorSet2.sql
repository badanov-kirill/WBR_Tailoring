CREATE PROCEDURE [Synchro].[ProductsForEAN_ErrorSet2]
	@pants_id INT,
	@error_num VARCHAR(10),
	@error_name VARCHAR(250),
	@error_desc VARCHAR(900),
	@error_xml VARCHAR(MAX)
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	DECLARE @dt DATETIME2(0) = GETDATE()
	
	BEGIN TRY
		BEGIN TRANSACTION 
		
		UPDATE	Synchro.ProductsForEANCnt2
		SET 	error_num = @error_num,
				error_name = @error_name,
				error_desc = @error_desc,
				error_xml = @error_xml,
				error_dt = @dt
		WHERE	pants_id = @pants_id
		
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