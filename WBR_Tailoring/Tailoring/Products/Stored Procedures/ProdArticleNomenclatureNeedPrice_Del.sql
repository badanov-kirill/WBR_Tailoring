CREATE PROCEDURE [Products].[ProdArticleNomenclatureNeedPrice_Del]
	@pan_id INT
AS
	SET NOCOUNT ON
	DECLARE @error_text VARCHAR(MAX)
	
	SELECT	@error_text = CASE 
	      	                   WHEN pan.pan_id IS NULL THEN 'Артикула цвета с кодом ' + CAST(v.pan_id AS VARCHAR(10)) + ' не существует'
	      	                   WHEN pan.whprice IS NULL OR pan.price_ru IS NULL THEN 'Нельзя удалять из очереди артикулы без цены'
	      	                   ELSE NULL
	      	              END
	FROM	(VALUES(@pan_id))v(pan_id)   
			LEFT JOIN	Products.ProdArticleNomenclature pan
				ON	pan.pan_id = v.pan_id
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	BEGIN TRY
	
		DELETE	
		FROM	Products.ProdArticleNomenclatureNeedPrice
		WHERE	pan_id = @pan_id
		
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