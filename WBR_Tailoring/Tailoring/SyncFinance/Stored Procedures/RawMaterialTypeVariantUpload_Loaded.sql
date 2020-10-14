CREATE PROCEDURE [SyncFinance].[RawMaterialTypeVariantUpload_Loaded]
	@rmtv_id INT,
	@rv_bigint BIGINT
AS
	SET NOCOUNT ON
	DECLARE @rv ROWVERSION = CAST(@rv_bigint AS ROWVERSION)
	
	BEGIN TRY
		DELETE	rmtvu
		FROM	SyncFinance.RawMaterialTypeVariantUpload rmtvu
		WHERE	rmtvu.rmtv_id = @rmtv_id
				AND	rmtvu.rv = @rv
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
		BEGIN
		    ROLLBACK TRANSACTION
		END
		
		DECLARE @ErrNum INT = ERROR_NUMBER();
		DECLARE @estate INT = ERROR_STATE();
		DECLARE @esev INT = ERROR_SEVERITY();
		DECLARE @Line INT = ERROR_LINE();
		DECLARE @Mess VARCHAR(MAX) = CHAR(10) + ISNULL('Процедура: ' + ERROR_PROCEDURE(), '') 
		        + CHAR(10) + ERROR_MESSAGE();
		
		
		RAISERROR('Ошибка %d в строке %d  %s', @esev, @estate, @ErrNum, @Line, @Mess) WITH LOG;
	END CATCH
GO	