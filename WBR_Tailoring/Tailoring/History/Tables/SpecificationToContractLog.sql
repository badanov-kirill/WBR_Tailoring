CREATE TABLE [History].[SpecificationToContractLog]
(
	log_id                  INT IDENTITY(1, 1) CONSTRAINT [PK_SpecificationToContractLog] PRIMARY KEY CLUSTERED NOT NULL,
	sct_id                  INT NOT NULL,
	dt                      DATETIME2(0) NOT NULL,
	supplier_id             INT NULL,
	currency_id             INT NULL,
	employee_id             INT NULL,
	material_cnt            SMALLINT NULL,
	material_amount_sum     DECIMAL(15, 2) NULL,
	material_qty_sum        DECIMAL(15, 3) NULL
)
