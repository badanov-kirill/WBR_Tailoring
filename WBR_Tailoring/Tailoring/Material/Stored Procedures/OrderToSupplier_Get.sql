CREATE PROCEDURE [Material].[OrderToSupplier_Get]
	@suppliercontract_id INT = NULL,
	@supplier_id INT = NULL,
	@dt_start DATE = NULL,
	@dt_finish DATE = NULL
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	ots.ots_id,
			CAST(ots.doc_dt AS DATETIME) doc_dt,
			es.employee_name,
			stopt.type_of_payment_name,
			ots.pay_prc1,
			ots.pay_prc2,
			ots.pay_prc3,
			ots.pay_prc4,
			ots.is_accounting_calendar,
			ots.delay_day_count,
			ots.is_start_received,
			ots.comment,
			ots.stc_id,
			c.currency_name_shot,
			ots.amount
	FROM	Material.OrderToSupplier ots   
			INNER JOIN	Suppliers.SupplierContract sc
				ON	sc.suppliercontract_erp_id = ots.suppliercontract_erp_id   
			LEFT JOIN	Settings.EmployeeSetting es
				ON	es.employee_id = ots.employee_id   
			LEFT JOIN	Material.SpecificationTypeOfPayment stopt
				ON	stopt.type_of_payment_id = ots.type_of_payment_id   
			LEFT JOIN	RefBook.Currency c
				ON	c.currency_id = sc.currency_id
	WHERE	(@suppliercontract_id IS NULL OR sc.suppliercontract_id = @suppliercontract_id)
			AND (@supplier_id IS NULL OR sc.supplier_id = @supplier_id)
			AND	(@dt_start IS NULL OR ots.doc_dt >= @dt_start)
			AND	(@dt_finish IS NULL OR ots.doc_dt <= DATEADD(DAY, 1, @dt_finish))
	