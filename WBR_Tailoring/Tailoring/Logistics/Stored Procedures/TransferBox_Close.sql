CREATE PROCEDURE [Logistics].[TransferBox_Close]
	@transfer_box_id BIGINT,
	@employee_id INT
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @dt DATETIME2(0) = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	
	SELECT	@error_text = CASE 
	      	                   WHEN tb.transfer_box_id IS NULL THEN 'Коробки с номером ' + CAST(v.transfer_box_id AS VARCHAR(20)) + 'не существует.'
	      	                   WHEN tb.close_dt IS NOT NULL THEN 'Коробки с номером ' + CAST(v.transfer_box_id AS VARCHAR(20)) + 'уже закрыта.'
	      	                   WHEN tbs.transfer_box_id IS NOT NULL AND (tbs.plan_shipping_dt < DATEADD(DAY, -2, @dt) OR tbs.plan_shipping_dt > DATEADD(DAY, 2, @dt)) THEN 
	      	                        'Коробка с номером ' + CAST(v.transfer_box_id AS VARCHAR(20)) + ' является специальной и запланирована на отгрузку ' + CONVERT(VARCHAR(20), tbs.plan_shipping_dt, 121) 
	      	                   ELSE NULL
	      	              END
	FROM	(VALUES(@transfer_box_id))v(transfer_box_id)   
			LEFT JOIN	Logistics.TransferBox tb
				ON	tb.transfer_box_id = v.transfer_box_id   
			LEFT JOIN	Logistics.TransferBoxSpecial tbs
				ON	tbs.transfer_box_id = tb.transfer_box_id 
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END 
	
	BEGIN TRY
		BEGIN TRANSACTION
		
		UPDATE	Logistics.TransferBox
		SET 	close_dt = @dt,
				close_employee_id = @employee_id
		WHERE	close_dt IS NULL
				AND	transfer_box_id = @transfer_box_id
				
		UPDATE	Logistics.TransferBoxSpecial
		SET 	shipping_dt              = @dt,
				shipping_employee_id     = @employee_id
		WHERE	transfer_box_id          = @transfer_box_id
		
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
		
		RAISERROR('Ошибка %d в строке %d  %s', @esev, @estate, @ErrNum, @Line, @Mess) WITH LOG;
	END CATCH 	