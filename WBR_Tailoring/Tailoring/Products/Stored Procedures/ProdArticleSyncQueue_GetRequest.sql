CREATE PROCEDURE [Products].[ProdArticleSyncQueue_GetRequest]
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	DECLARE @dt DATETIME2(0) = GETDATE()
	DECLARE @state TINYINT = 5	
	
	BEGIN TRY
		BEGIN TRANSACTION
		
		DELETE	Products.ProdArticleSyncQueue
		      	OUTPUT	@state,
		      			DELETED.pa_id,
		      			DELETED.spec_uid,
		      			@dt
		      	INTO	Products.ProdArticleSyncError (
		      			pass_id,
		      			pa_id,
		      			spec_uid,
		      			dt
		      		)
		WHERE	cnt_request > 9
		
		UPDATE	pasq
		SET 	cnt_request = cnt_request + 1
		    	OUTPUT	INSERTED.pa_id,
		    			CAST(CAST(INSERTED.rv AS BIGINT) AS VARCHAR(20)) rv_bigint,
		    			INSERTED.spec_uid
		FROM	Products.ProdArticleSyncQueue pasq
		WHERE	pasq.spec_uid IS NOT NULL
				AND pasq.request_dt IS NULL
				AND	(
				   		CASE 
				   		     WHEN pasq.cnt_request < 3
				   		AND DATEDIFF(minute, pasq.send_dt, @dt) > 5 THEN 1 
				   		    WHEN pasq.cnt_request < 5
				   		AND DATEDIFF(hour, pasq.send_dt, @dt) > 24 THEN 1
				   		    WHEN pasq.cnt_request < 7
				   		AND DATEDIFF(hour, pasq.send_dt, @dt) > 48 THEN 1
				   		    ELSE 0
				   		    END
				   	) = 1
		
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