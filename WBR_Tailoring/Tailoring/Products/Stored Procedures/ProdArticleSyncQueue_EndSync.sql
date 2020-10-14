CREATE PROCEDURE [Products].[ProdArticleSyncQueue_EndSync]
	@pa_id INT,
	@rv_bigint VARCHAR(20)
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @rv ROWVERSION = CAST(CAST(@rv_bigint AS BIGINT) AS ROWVERSION)
	
	BEGIN TRY
		BEGIN TRANSACTION
		
		DELETE	
		FROM	Products.ProdArticleSyncQueue
		WHERE	pa_id = @pa_id
				AND	rv = @rv
		
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