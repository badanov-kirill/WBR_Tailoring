CREATE TABLE [Material].[SpecificationToContract]
(
	stc_id                     INT CONSTRAINT [PK_SpecificationToContract] PRIMARY KEY CLUSTERED NOT NULL,
	doc_dt                     DATETIME2(0) NOT NULL,
	supplier_id                INT NULL,
	suppliercontract_erp_id    INT NULL,
	employee_id                INT NOT NULL,
	type_of_payment_id         INT NULL,
	pay_prc1                   DECIMAL(5, 2) NULL,
	pay_prc2                   DECIMAL(5, 2) NULL,
	pay_prc3                   DECIMAL(5, 2) NULL,
	pay_prc4                   DECIMAL(5, 2) NULL,
	is_accounting_calendar     BIT NULL,
	accept_dt                  DATE NULL,
	delay_day_count            INT NULL,
	is_start_received          BIT NULL,
	comment                    VARCHAR(100) NULL,
	is_price_list              BIT NULL,
	currency_id                INT NULL,
	dt_calc_in                 DATE NULL
)