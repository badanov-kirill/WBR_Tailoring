CREATE PROCEDURE [Wildberries].[ProdArticleForWB_SetSave]
	@pa_id INT,
	@imt_uid CHAR(36),
	@pan_tab dbo.List READONLY
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ COMMITTED
	SET XACT_ABORT ON
	
	DECLARE @dt DATETIME2(0) = GETDATE()
		
	BEGIN TRY
		BEGIN TRANSACTION 
		
		UPDATE	Wildberries.ProdArticleForWB
		SET 	send_dt = @dt,
				imt_uid = dbo.uid2bin(@imt_uid)
		WHERE	pa_id = @pa_id
		
		INSERT INTO Wildberries.ProdArticleNomenclatureForWB
			(
				pan_id,
				pa_id,
				dt
			)
		SELECT	t.id,
				@pa_id,
				@dt
		FROM	@pan_tab t
		WHERE	NOT EXISTS(
		     		SELECT	1
		     		FROM	Wildberries.ProdArticleNomenclatureForWB panfw
		     		WHERE	panfw.pan_id = t.id
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
		
		RAISERROR('Ошибка %d в строке %d  %s', @esev, @estate, @ErrNum, @Line, @Mess) 
		WITH LOG;
	END CATCH
GO