CREATE PROCEDURE [Suppliers].[SupplierContract_Get]
	@supplier_id INT = NULL
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED	
	
	SELECT	sc.suppliercontract_id,
			'(' + ISNULL(c.currency_name_shot, ' ') + ') ' + sc.suppliercontract_name suppliercontract_name,
			sc.is_default,
			sc.supplier_id,
			sc.contract_number, 
			sc.payment_delay_day
	FROM	Suppliers.SupplierContract sc
	LEFT JOIN RefBook.Currency c ON c.currency_id = sc.currency_id
	WHERE	@supplier_id IS NULL
			OR	sc.supplier_id = @supplier_id