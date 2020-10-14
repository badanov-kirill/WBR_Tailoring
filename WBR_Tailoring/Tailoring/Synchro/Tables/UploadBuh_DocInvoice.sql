CREATE TABLE [Synchro].[UploadBuh_DocInvoice]
(
	doc_id                 INT NOT NULL,
	upload_doc_type_id     TINYINT NOT NULL,
	invoice_name           VARCHAR(30) NOT NULL,
	invoice_dt             DATE NOT NULL,
	edo                    BIT NOT NULL,
	amount_with_nds        DECIMAL(9, 2) NOT NULL,
	amount_nds             DECIMAL(9, 2) NOT NULL,
	amount_without_nds     DECIMAL(9, 2) NOT NULL,
	ttn_name               VARCHAR(30) NULL,
	ttn_dt                 DATE NULL,
	CONSTRAINT [PK_UploadBuh_DocInvoice] PRIMARY KEY CLUSTERED(doc_id, upload_doc_type_id, invoice_name, invoice_dt)
)
