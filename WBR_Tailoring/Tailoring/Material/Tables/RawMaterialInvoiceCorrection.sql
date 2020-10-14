CREATE TABLE [Material].[RawMaterialInvoiceCorrection]
(
	rmic_id                INT IDENTITY(1, 1) CONSTRAINT [PK_RawMaterialInvoiceCorrection] PRIMARY KEY CLUSTERED NOT NULL,
	rmi_id                 INT CONSTRAINT [FK_RawMaterialInvoiceCorrection] FOREIGN KEY REFERENCES Material.RawMaterialInvoice(rmi_id) NOT NULL,
	base_invoice_name      VARCHAR(30) NOT NULL,
	base_invoice_dt        DATE NOT NULL,
	buch_num               VARCHAR(30) NULL,
	create_dt              DATETIME2(0) NOT NULL,
	create_employee_id     INT NOT NULL,
	dt                     DATETIME2(0) NOT NULL,
	employee_id            INT,
	comment                VARCHAR(500) NULL,
	close_dt               DATETIME2(0) NULL,
	close_employee_id      INT NULL,
	amount_invoice         DECIMAL(9, 2) NOT NULL,
	amount_shk             DECIMAL(9, 2) NOT NULL,
	rmict_id               TINYINT CONSTRAINT [FK_RawMaterialInvoiceCorrection_rmict_id] FOREIGN KEY REFERENCES Material.RawMaterialInvoiceCorrectionType(rmict_id) NOT NULL
)
