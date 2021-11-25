CREATE PROCEDURE [SyncFinance].[Fine_Loaded]
	@table SyncFinance.LoadedId READONLY
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	BEGIN TRY
		DELETE	f
		FROM	SyncFinance.Fine f   
				INNER JOIN	@table t
					ON	f.id = t.id
					AND f.rv = t.rv
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


GO