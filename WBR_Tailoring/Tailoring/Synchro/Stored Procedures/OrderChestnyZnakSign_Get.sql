CREATE PROCEDURE [Synchro].[OrderChestnyZnakSign_Get]
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ COMMITTED
	
	DECLARE @TabOut TABLE (ocz_id INT, body_text NVARCHAR(MAX), signature_text NVARCHAR(max), fabricator_id int)
	
	BEGIN TRY
		UPDATE	Synchro.OrderChestnyZnakSign
		SET 	count_send = count_send + 1
		    	OUTPUT	INSERTED.ocz_id,
		    			INSERTED.body_text,
		    			INSERTED.signature_text,
		    			INSERTED.fabricator_id
		    			INTO @TabOut
						(
							ocz_id,
							body_text,
							signature_text,
							fabricator_id
						)
		WHERE	count_send < 10
		
		SELECT tot.ocz_id,tot.body_text,tot.signature_text,tot.fabricator_id,f.CZ_Token,f.CZ_TokenDT,f.CZ_omsId
		FROM @TabOut AS tot
		INNER JOIN Settings.Fabricators AS f ON f.fabricator_id = tot.fabricator_id
		
		
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
