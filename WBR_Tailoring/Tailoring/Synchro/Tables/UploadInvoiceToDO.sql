CREATE TABLE [Synchro].[UploadInvoiceToDO]
(
	invoice_id          INT NOT NULL,
	supplier_id         INT NOT NULL,
	invoice_name        VARCHAR(30) NOT NULL,
	invoice_dt          DATE NOT NULL,
	amount_with_nds     DECIMAL(9, 2) NOT NULL,
	num_ots             INT NULL,
	rv                  ROWVERSION NOT NULL,
	CONSTRAINT [PK_UploadInvoiceToDO] PRIMARY KEY CLUSTERED(invoice_id)
)
