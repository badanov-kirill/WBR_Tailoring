CREATE PROCEDURE [Synchro].[NM_Load]
	@data_tab Synchro.NM_Load_Type READONLY
AS
	SET NOCOUNT ON
	
	BEGIN TRY
		BEGIN TRANSACTION 
		
		UPDATE	pan
		SET 	nm_id = dt.nm_id
		FROM	@data_tab dt
				INNER JOIN	Products.ProdArticle pa
				INNER JOIN	Products.ProdArticleNomenclature pan
					ON	pan.pa_id = pa.pa_id
					ON	pa.sa + pan.sa = dt.sa
		WHERE	pan.nm_id IS NULL
		
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
	