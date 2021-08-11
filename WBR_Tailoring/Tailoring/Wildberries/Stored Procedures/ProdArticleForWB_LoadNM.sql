CREATE PROCEDURE [Wildberries].[ProdArticleForWB_LoadNM]
	@pa_id INT,
	@imt_id INT,
	@nm_tab Wildberries.LoadNomenclatureTab READONLY
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ COMMITTED
	SET XACT_ABORT ON
	
	DECLARE @dt DATETIME2(0) = GETDATE()
	
	BEGIN TRY
		BEGIN TRANSACTION 
		
		UPDATE	panfw
		SET 	nm_id = nt.nm_id
		FROM	Wildberries.ProdArticleNomenclatureForWB panfw
				INNER JOIN	Products.ProdArticleNomenclature pan
					ON	pan.pan_id = panfw.pan_id
					AND	pan.is_deleted = 0
				INNER JOIN	@nm_tab nt
					ON	pan.sa = nt.sa_nm
		WHERE	panfw.pa_id = @pa_id
				AND	panfw.nm_id IS NULL
		
		UPDATE	pa
		SET 	pa.imt_id = @imt_id
		FROM	Products.ProdArticle pa
		WHERE	pa.pa_id = @pa_id
				AND	pa.is_deleted = 0
				AND	pa.imt_id IS NULL
				AND	NOT EXISTS(
				   		SELECT	1
				   		FROM	Products.ProdArticle pa2
				   		WHERE	pa2.imt_id = @imt_id
				   	)
		
		UPDATE	pan
		SET 	nm_id = nt.nm_id
		FROM	Products.ProdArticleNomenclature pan
				INNER JOIN	@nm_tab nt
					ON	pan.sa = nt.sa_nm
		WHERE	pan.pa_id = @pa_id
				AND	pan.is_deleted = 0
				AND	pan.nm_id IS NULL
				AND	NOT EXISTS(
				   		SELECT	1
				   		FROM	Products.ProdArticleNomenclature pan2
				   		WHERE	pan2.nm_id = nt.nm_id
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