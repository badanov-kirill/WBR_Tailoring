CREATE PROCEDURE [Wildberries].[ProdArticleForWB_SetError]
	@pa_id INT,
	@fabricator_id INT,
	@send_type VARCHAR(10),
	@error_text VARCHAR(MAX),
	@send_message VARCHAR(MAX) = NULL,
	@error_code		 VARCHAR(5) = NULL
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ COMMITTED
	SET XACT_ABORT ON
	
	DECLARE @dt DATETIME = GETDATE()
	
	BEGIN TRY
		BEGIN TRANSACTION 
		
		UPDATE	Wildberries.ProdArticleForWB
		SET 	is_error = 1
		WHERE	pa_id = @pa_id
			AND fabricator_id = @fabricator_id
		
		INSERT INTO Wildberries.ProdArticleForWBError
			(
				pa_id,
				dt,
				error_text,
				send_message,
				send_type,
				error_code,
				fabricator_id
			)
		VALUES
			(
				@pa_id,
				@dt,
				@error_text,
				@send_message,
				@send_type,
				@error_code,
				@fabricator_id
			)
		
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
		
		RAISERROR('Ошибка %d в строке %d  %s', @esev, @estate, @ErrNum, @Line, @Mess) ;
		--WITH LOG;
	END CATCH
GO