CREATE PROCEDURE [Wildberries].[ProdArticleForWB_GetForLoadNM]
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ COMMITTED
	
	DECLARE @tab TABLE (pa_id INT)
	DECLARE @dt DATETIME2(0) = GETDATE()
	
	BEGIN TRY
		UPDATE	p
		SET 	cnt_load = cnt_load + 1
		    	OUTPUT	INSERTED.pa_id
		    	INTO	@tab (
		    			pa_id
		    		)
		FROM	Wildberries.ProdArticleForWBCnt p
				INNER JOIN	Wildberries.ProdArticleForWB pafw
					ON	pafw.pa_id = p.pa_id
		WHERE	p.cnt_load < 10
				AND	DATEADD(hour, p.cnt_load + 1, p.dt_save) < @dt
				AND	pafw.send_dt IS NOT NULL
		
		SELECT	pafw.pa_id,
				dbo.bin2uid(pafw.imt_uid) imt_uid,
				pa.sa,
				b.brand_name
		FROM	@tab t   
				INNER JOIN	Wildberries.ProdArticleForWB pafw
					ON	pafw.pa_id = t.pa_id   
				INNER JOIN	Products.ProdArticle pa
					ON	pa.pa_id = pafw.pa_id
				INNER JOIN Products.Brand b
					ON b.brand_id = pa.brand_id
				
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