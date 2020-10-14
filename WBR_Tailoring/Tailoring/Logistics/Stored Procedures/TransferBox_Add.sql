CREATE PROCEDURE [Logistics].[TransferBox_Add]
	@transfer_box_id BIGINT,
	@employee_id INT,
	@plan_shipping_dt DATE = NULL
AS
	SET NOCOUNT ON
	DECLARE @dt DATETIME2(0) = GETDATE()
	
	BEGIN TRY
		INSERT INTO Logistics.TransferBox
			(
				transfer_box_id,
				create_dt,
				create_employee_id,
				plan_shipping_dt
			)
		SELECT	@transfer_box_id,
				@dt,
				@employee_id,
				@plan_shipping_dt
		WHERE	NOT EXISTS (
		     		SELECT	1
		     		FROM	Logistics.TransferBox tb
		     		WHERE	tb.transfer_box_id = @transfer_box_id
		     	)
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