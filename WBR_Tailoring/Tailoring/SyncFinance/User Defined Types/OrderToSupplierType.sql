CREATE TYPE [SyncFinance].[OrderToSupplierType] AS TABLE
(
	id INT NOT NULL,
	ots_id INT NOT NULL,
	doc_dt DATETIME2(0) NOT NULL,
	supplier_id INT NULL,
	supplier_contract_id INT NULL,
	employee_id INT NOT NULL,
	type_of_payment_id INT NULL,
	type_of_payment_name VARCHAR(100) NULL,
	pay_prc1 DECIMAL(5, 2) NULL,
	pay_prc2 DECIMAL(5, 2) NULL,
	pay_prc3 DECIMAL(5, 2) NULL,
	pay_prc4 DECIMAL(5, 2) NULL,
	is_accounting_calendar BIT NULL,
	delay_day_count INT NULL,
	is_start_received BIT NULL,
	comment VARCHAR(100) NULL,
	currency_id INT NULL,
	amount DECIMAL(15, 2) NULL,
	stc_id INT NULL,
	rv BIGINT NOT NULL
)
GO

GRANT EXECUTE
    ON TYPE::[SyncFinance].[OrderToSupplierType] TO PUBLIC;
GO