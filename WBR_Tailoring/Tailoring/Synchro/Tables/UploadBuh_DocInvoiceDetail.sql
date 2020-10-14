CREATE TABLE [Synchro].[UploadBuh_DocInvoiceDetail]
(
	doc_id                 INT NOT NULL,
	upload_doc_type_id     TINYINT NOT NULL,
	invoice_name           VARCHAR(30) NOT NULL,
	invoice_dt             DATE NOT NULL,
	rmt_id                 INT NOT NULL,
	nds                    TINYINT NOT NULL,
	amount                 DECIMAL(9, 2) NOT NULL,
	ttn_name               VARCHAR(30) NULL,
	ttn_dt                 DATE NULL,
	amount_cur			   DECIMAL(9, 2) NULL,
	CONSTRAINT [PK_UploadBuh_DocInvoiceDetail] PRIMARY KEY CLUSTERED(doc_id, upload_doc_type_id, invoice_name, invoice_dt, rmt_id, nds)
)              