CREATE PROCEDURE [Ozon].[AttributeValuesUsed_Set]
	@data Ozon.AttributeValuesType READONLY
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	BEGIN TRY
		BEGIN TRANSACTION
		
		UPDATE	av
		SET 	is_used = d.is_used
		FROM	Ozon.AttributeValues av
				INNER JOIN	@data d
					ON	av.av_id = av.av_id
		
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
