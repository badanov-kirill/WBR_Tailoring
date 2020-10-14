CREATE TABLE [History].[OrderToSupplierLog]
(
	log_id                  INT IDENTITY(1, 1) CONSTRAINT [PK_OrderToSupplierLog] PRIMARY KEY CLUSTERED NOT NULL,
	ots_id                  INT NOT NULL,
	dt                      DATETIME2(0) NOT NULL,
	supplier_id             INT NULL,
	currency_id             INT NULL,
	employee_id             INT NULL,
	material_cnt            SMALLINT NULL,
	material_amount_sum     DECIMAL(15, 2) NULL,
	material_qty_sum        DECIMAL(15, 3) NULL
)
