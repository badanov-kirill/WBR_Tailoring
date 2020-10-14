CREATE PROCEDURE [SyncFinance].[MaterialStuffSupply_Loaded]
	@table SyncFinance.LoadedId READONLY
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	BEGIN TRY
	BEGIN TRANSACTION 
		DELETE	sd
		FROM	SyncFinance.MaterialStuffSupplyDetail sd   
				INNER JOIN	SyncFinance.MaterialStuffSupply si
					ON	si.doc_id = sd.doc_id   
				INNER JOIN	@table t
					ON	si.doc_id = t.id
					AND	si.rv = t.rv
					
		DELETE	si
		FROM	SyncFinance.MaterialStuffSupply si  
				INNER JOIN	@table t
					ON	si.doc_id = t.id
					AND	si.rv = t.rv
					
	COMMIT TRANSACTION		
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

GRANT EXECUTE
    ON OBJECT::[SyncFinance].[MaterialStuffSupply_Loaded] TO [WILDBERRIES\FinanceServices]
    AS [dbo];
GO