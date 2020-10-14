CREATE PROCEDURE [Manufactory].[ProductUniqDataMatrixSeq_Get]
	@count SMALLINT
AS
	SET NOCOUNT ON
	
	IF @count > 600
	BEGIN
	    RAISERROR('Нельзя печатать больше 600 наклеек единовременно', 16, 1)
	    RETURN
	END
	
	BEGIN TRY
		SELECT	NEXT VALUE
		FOR Manufactory.ProductUniqDataMatrixSeq  AS unic_code
		    FROM dbo.Number            n
		    WHERE n.id > 0
		    AND n.id <= @count
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