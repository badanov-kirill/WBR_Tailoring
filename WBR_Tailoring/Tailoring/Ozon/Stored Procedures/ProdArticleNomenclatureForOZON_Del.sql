CREATE PROCEDURE [Ozon].[ProdArticleNomenclatureForOZON_Del]
	@pan_id INT,
	@employee_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ COMMITTED
	SET XACT_ABORT ON
	
	DECLARE @dt DATETIME2(0) = GETDATE()
	
	BEGIN TRY
		BEGIN TRANSACTION 
		
		UPDATE	Ozon.ProdArticleNomenclatureForOZON
		SET 	is_deleted = 1,
				employee_id = @employee_id
		WHERE	pan_id = @pan_id 
		
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
		
		RAISERROR('Ошибка %d в строке %d  %s', @esev, @estate, @ErrNum, @Line, @Mess) 
		WITH LOG;
	END CATCH
GO