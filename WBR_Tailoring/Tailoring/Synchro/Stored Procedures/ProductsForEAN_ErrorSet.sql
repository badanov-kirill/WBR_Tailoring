CREATE PROCEDURE [Synchro].[ProductsForEAN_ErrorSet]
	@pants_id INT,
	@fabricator_id INT,
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
		
		UPDATE	Synchro.ProductsForEANCnt
		SET 	error_num = @error_num,
				error_name = @error_name,
				error_desc = @error_desc,
				error_xml = @error_xml,
				error_dt = @dt
		WHERE	pants_id = @pants_id
				AND fabricator_id = @fabricator_id 
		
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
		
		
		RAISERROR('Ошибка %d в строке %d  %s', @esev, @estate, @ErrNum, @Line, @Mess); 
	END CATCH
GO

