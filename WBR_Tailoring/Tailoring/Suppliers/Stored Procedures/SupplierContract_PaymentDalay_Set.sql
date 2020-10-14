CREATE PROCEDURE [Suppliers].[SupplierContract_PaymentDalay_Set]
	@suppliercontract_id INT,
	@payment_delay_day SMALLINT
AS
	SET NOCOUNT ON
	
	IF NOT EXISTS (
	   	SELECT	1
	   	FROM	Suppliers.SupplierContract sc
	   	WHERE	sc.suppliercontract_id = @suppliercontract_id
	   )
	BEGIN
	    RAISERROR('Договора поставщика с кодом %d не существует', 16, 1, @suppliercontract_id)
	    RETURN
	END
	
	BEGIN TRY
		UPDATE	Suppliers.SupplierContract
		SET 	payment_delay_day       = @payment_delay_day
		WHERE	suppliercontract_id     = @suppliercontract_id
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