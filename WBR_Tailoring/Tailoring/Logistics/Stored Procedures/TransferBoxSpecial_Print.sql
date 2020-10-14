CREATE PROCEDURE [Logistics].[TransferBoxSpecial_Print]
	@transfer_box_id BIGINT,
	@employee_id INT
AS
	SET NOCOUNT ON
	DECLARE @dt DATETIME2(0) = GETDATE()
	
	DECLARE @error_text VARCHAR(MAX)
	
	SELECT	@error_text = CASE 
	      	                   WHEN tbs.transfer_box_id IS NULL THEN 'Спец коробки с кодом ' + CAST(v.transfer_box_id AS VARCHAR(20)) + ' не существует.'
	      	                   WHEN tb.close_dt IS NOT NULL THEN 'Коробка с кодом ' + CAST(v.transfer_box_id AS VARCHAR(20)) + ' уже закрыта.'
	      	                   WHEN tbs.shipping_dt IS NOT NULL THEN 'Коробка с кодом ' + CAST(v.transfer_box_id AS VARCHAR(20)) + ' уже закрыта.'
	      	                   WHEN tbs.print_dt IS NOT NULL THEN 'Коробка с кодом ' + CAST(v.transfer_box_id AS VARCHAR(20)) + ' уже напечатана.'
	      	                   ELSE NULL
	      	              END
	FROM	(VALUES(@transfer_box_id))v(transfer_box_id)   
			LEFT JOIN	Logistics.TransferBoxSpecial tbs   
			INNER JOIN	Logistics.TransferBox tb
				ON	tb.transfer_box_id = tbs.transfer_box_id
				ON	tbs.transfer_box_id = v.transfer_box_id
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	BEGIN TRY
		UPDATE	Logistics.TransferBoxSpecial
		SET 	print_dt              = @dt,
				print_employee_id     = @employee_id
		WHERE	transfer_box_id       = @transfer_box_id
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