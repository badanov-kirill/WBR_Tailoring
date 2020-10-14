CREATE PROCEDURE [Products].[ProdArticleNomenclature_PriceUpd]
	@pan_id INT,
	@price_ru DECIMAL(9, 2),
	@whprice DECIMAL(9, 2),
	@employee_id INT
AS
	SET NOCOUNT ON 
	SET XACT_ABORT ON
	
	DECLARE @dt dbo.SECONDSTIME = GETDATE()
	
	IF NOT EXISTS (
	   	SELECT	1
	   	FROM	Products.ProdArticleNomenclature pan
	   	WHERE	pan.pan_id = @pan_id
	   )
	BEGIN
	    RAISERROR('Артикула номенклатуры с кодом %d не существует', 16, 1, @pan_id)
	    RETURN
	END
	
	IF ISNULL(@price_ru, 0) = 0
	BEGIN
	    RAISERROR('Не указана цена', 16, 1)
	    RETURN
	END
	
	IF ISNULL(@whprice, 0) = 0
	BEGIN
	    RAISERROR('Не указана себестоимость', 16, 1)
	    RETURN
	END
	
	BEGIN TRY
		BEGIN TRANSACTION 
		
		UPDATE	Products.ProdArticleNomenclature
		SET 	whprice = @whprice,
				price_ru = @price_ru
				OUTPUT	INSERTED.pan_id,
						INSERTED.pa_id,
						INSERTED.sa,
						INSERTED.is_deleted,
						INSERTED.employee_id,
						INSERTED.dt,
						INSERTED.nm_id,
						INSERTED.whprice,
						INSERTED.price_ru,
						INSERTED.cutting_degree_difficulty
				INTO	History.ProdArticleNomenclature (
						pan_id,
						pa_id,
						sa,
						is_deleted,
						employee_id,
						dt,
						nm_id,
						whprice,
						price_ru,
						cutting_degree_difficulty
					)
		WHERE	pan_id = @pan_id
		
		INSERT INTO History.ProdArticleNomenclaturePrice
		  (
		    pan_id,
		    whprice,
		    price_ru,
		    employee_id,
		    dt
		  )
		VALUES
		  (
		    @pan_id,
		    @whprice,
		    @pan_id,
		    @employee_id,
		    @dt
		  )
		
		DELETE	
		FROM	Products.ProdArticleNomenclatureNeedPrice
		WHERE	pan_id = @pan_id
		
		
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