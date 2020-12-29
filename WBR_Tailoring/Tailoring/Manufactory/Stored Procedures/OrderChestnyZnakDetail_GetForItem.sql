CREATE PROCEDURE [Manufactory].[OrderChestnyZnakDetail_GetForItem]
AS
	SET NOCOUNT ON
	DECLARE @dt DATETIME2(0) = GETDATE()
	DECLARE @tab_out TABLE (oczd_id INT)
	
	BEGIN TRY
		UPDATE	Synchro.OrderChestnyZnakCntLoadItem
		SET 	cnt_load = cnt_load + 1,
				dt = @dt,
				timeout_second = timeout_second + 600
				OUTPUT	INSERTED.oczd_id
				INTO	@tab_out (
						oczd_id
					)
		WHERE	cnt_load < 10
				AND	DATEDIFF(second, dt, @dt) > timeout_second
		
		SELECT	ocz.ocz_id,
				LOWER(dbo.bin2uid(ocz.ocz_uid)) ocz_uid,
				oczd.ean,
				oczd.cnt,
				oczd.oczd_id
		FROM	Manufactory.OrderChestnyZnak ocz   
				INNER JOIN	Manufactory.OrderChestnyZnakDetail oczd
					ON	oczd.ocz_id = ocz.ocz_id   
				INNER JOIN	@tab_out c
					ON	oczd.oczd_id = c.oczd_id
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