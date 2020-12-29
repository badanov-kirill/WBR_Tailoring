CREATE PROCEDURE [Synchro].[OrderChestnyZnakSign_Load]
	@ocz_id INT,
	@ocz_uid CHAR(36),
	@timeout_second INT
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	DECLARE @dt DATETIME2(0) = GETDATE()
	DECLARE @ocz_uid_bin BINARY(16) = dbo.uid2bin(@ocz_uid)
	
	BEGIN TRY
		BEGIN TRANSACTION 
		
		UPDATE	Manufactory.OrderChestnyZnak
		SET 	send_dt = @dt,
				ocz_uid = @ocz_uid_bin
		WHERE	ocz_id = @ocz_id
		
		DELETE	Synchro.OrderChestnyZnakSign
		WHERE	ocz_id = @ocz_id
		
		INSERT INTO Synchro.OrderChestnyZnakCntLoadItem
			(
				oczd_id,
				cnt_load,
				dt,
				timeout_second
			)
		SELECT	oczd.oczd_id,
				0,
				@dt,
				@timeout_second
		FROM	Manufactory.OrderChestnyZnakDetail oczd
		WHERE	oczd.ocz_id = @ocz_id
		
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
	

