CREATE PROCEDURE [Products].[ProdArticleNomenclature_UpdCDD_v2]
	@pan_id INT,
	@cutting_degree_difficulty DECIMAL(4, 2),
	@employee_id INT
AS
	SET NOCOUNT ON
	DECLARE @dt DATETIME2(0) = GETDATE()
	
	IF NOT EXISTS (
	   	SELECT	1
	   	FROM	Products.ProdArticleNomenclature pan
	   	WHERE	pan.pan_id = @pan_id
	   )
	BEGIN
	    RAISERROR('Цветоварианта с кодом %d не существует', 16, 1, @pan_id)
	    RETURN
	END
	
	BEGIN TRY
		UPDATE	pan
		SET 	cutting_degree_difficulty = @cutting_degree_difficulty,
				employee_id = @employee_id,
				dt = @dt
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
		FROM	Products.ProdArticleNomenclature pan
		WHERE	pan.pan_id = @pan_id
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