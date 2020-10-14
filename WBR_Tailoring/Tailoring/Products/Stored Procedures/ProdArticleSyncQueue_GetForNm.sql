CREATE PROCEDURE [Products].[ProdArticleSyncQueue_GetForNm]
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	DECLARE @dt DATETIME2(0) = GETDATE()
	DECLARE @state TINYINT = 8
	DECLARE @tab TABLE(pa_id INT, rv_bigint BIGINT, spec_uid VARCHAR(36))
	
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
		WHERE	cnt_get_nm > 9
		
		UPDATE	pasq
		SET 	cnt_get_nm = cnt_get_nm + 1
		    	OUTPUT	INSERTED.pa_id,
		    			CAST(CAST(INSERTED.rv AS BIGINT) AS VARCHAR(20)) rv_bigint,
		    			INSERTED.spec_uid
		    	INTO	@tab (
		    			pa_id,
		    			rv_bigint,
		    			spec_uid
		    		)
		FROM	Products.ProdArticleSyncQueue pasq
		WHERE	pasq.request_dt IS NOT NULL
				AND	(
				   		CASE 
				   		     WHEN pasq.cnt_get_nm < 3
				   		AND DATEDIFF(minute, pasq.request_dt, @dt) > 1 THEN 1 
				   		    WHEN pasq.cnt_get_nm < 5
				   		AND DATEDIFF(hour, pasq.request_dt, @dt) > 24 THEN 1
				   		    WHEN pasq.cnt_get_nm < 7
				   		AND DATEDIFF(hour, pasq.request_dt, @dt) > 48 THEN 1
				   		    ELSE 0
				   		    END
				   	) = 1
		
		COMMIT TRANSACTION
		
		SELECT	t.pa_id,
				t.rv_bigint,
				t.spec_uid
		FROM	@tab t
		
		SELECT	pan.pan_id,
				pan.pa_id,
				pa.sa        sa,
				pan.sa       color_sa,
				pan.nm_id,
				b.erp_id     brand_erp_id
		FROM	Products.ProdArticleNomenclature pan   
				INNER JOIN	Products.ProdArticle pa
					ON	pa.pa_id = pan.pa_id   
				INNER JOIN	Products.Brand b
					ON	b.brand_id = pa.brand_id   
				INNER JOIN	@tab t
					ON	t.pa_id = pan.pa_id
		WHERE	pa.is_deleted = 0
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