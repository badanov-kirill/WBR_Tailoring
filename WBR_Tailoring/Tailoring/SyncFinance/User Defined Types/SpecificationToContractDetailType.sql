CREATE TYPE [SyncFinance].[SpecificationToContractDetailType] AS TABLE
(
	id INT NOT NULL,
	stc_id INT NOT NULL,
	nomenclature_code VARCHAR(250) NULL,
	nomenclature_name VARCHAR(500) NULL,
	tmc_id INT NULL,
	tmc_name VARCHAR(100) NULL,
	qty DECIMAL(15, 3) NOT NULL,
	price DECIMAL(15, 2) NULL,
	vat_value TINYINT,
	amount DECIMAL(15, 2) NULL,
	okei_id INT NULL,
	receipt_dt DATE NULL,
	days_before_pay INT NULL,
	plan_pay_dt DATE NULL,
	price_with_vat DECIMAL(15, 2) NULL
)
GO

GRANT EXECUTE
    ON TYPE::[SyncFinance].[SpecificationToContractDetailType] TO PUBLIC;
GO