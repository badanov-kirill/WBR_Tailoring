CREATE PROCEDURE [Synchro].[RV_Set]
	@vc_log_id VARCHAR(20),
	@ob_name VARCHAR(10)
AS
	SET NOCOUNT ON
	
	DECLARE @log_id BIGINT = CAST(@vc_log_id AS BIGINT)
	DECLARE @dt DATETIME2(0) = GETDATE()
	
	BEGIN TRY
		UPDATE	Synchro.RV
		SET 	object_rv     = CASE 
		    	                 WHEN object_rv > @log_id THEN object_rv
		    	                 ELSE @log_id
		    	            END,
				dt            = @dt
		WHERE	ob_name       = @ob_name
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
	