CREATE PROCEDURE [Ozon].[ArticleSaveTask_Add]
	@task_id BIGINT,
	@pan_id INT,
	@pants_tab dbo.List READONLY
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ COMMITTED
	SET XACT_ABORT ON
	
	DECLARE @dt DATETIME2(0) = GETDATE()
	IF ISNULL(@task_id, 0) = 0
	BEGIN
		RAISERROR('Не корректный номер задания',16,1)
		RETURN
	END
	
	BEGIN TRY
		BEGIN TRANSACTION 
		
		UPDATE	Ozon.ProdArticleNomenclatureForOZON
		SET 	send_dt = @dt
		WHERE	pan_id = @pan_id
		
		INSERT INTO Ozon.ArticleSaveTask
			(
				task_id,
				dt,
				dt_save,
				dt_load
			)
		VALUES
			(
				@task_id,
				@dt,
				@dt,
				NULL
			)
		
		INSERT INTO Ozon.ArticleSaveTaskProdArticleTS
			(
				task_id,
				pants_id,
				dt
			)
		SELECT	@task_id,
				dt.id,
				@dt
		FROM	@pants_tab dt
		
		
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
	