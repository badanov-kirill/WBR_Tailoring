CREATE PROCEDURE [Wildberries].[ProdArticleForWB_LoadNM_v3]
	@pa_id INT,
	@sa VARCHAR(76),
	@nm_id int
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ COMMITTED
	SET XACT_ABORT ON
	
	DECLARE @dt DATETIME2(0) = GETDATE()
	
	BEGIN TRY
		BEGIN TRANSACTION 
		
		UPDATE	pan
		SET 	nm_id = @nm_id
		FROM	Products.ProdArticleNomenclature pan
		INNER JOIN Products.ProdArticle pa ON pa.pa_id = pan.pa_id
		WHERE	pan.pa_id = @pa_id
				AND	pan.is_deleted = 0
				AND	pan.nm_id IS NULL
				AND pa.sa + pan.sa = @sa
				AND	NOT EXISTS(
				   		SELECT	1
				   		FROM	Products.ProdArticleNomenclature pan2
				   		WHERE	pan2.nm_id = @nm_id
				   	)
		
		IF NOT EXISTS (
		   	SELECT	1
		   	FROM	Wildberries.ProdArticleNomenclatureForWB panfw
		   	WHERE	panfw.pa_id = @pa_id
		   			AND	panfw.nm_id IS NULL
		   )
		BEGIN
		    UPDATE	Wildberries.ProdArticleForWB
		    SET 	load_nm_dt = @dt,
		    		is_error = 0
		    WHERE	pa_id = @pa_id
		    
		    DELETE	
		    FROM	Wildberries.ProdArticleForWBCnt
		    WHERE	pa_id = @pa_id
		    
		    DELETE	
		    FROM	Wildberries.ProdArticleForWBError
		    WHERE	pa_id = @pa_id
		END
		
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