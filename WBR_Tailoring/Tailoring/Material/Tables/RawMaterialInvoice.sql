CREATE TABLE [Material].[RawMaterialInvoice]
(
	rmi_id                  INT NOT NULL IDENTITY(1, 1) CONSTRAINT [PK_RawMaterialInvoice] PRIMARY KEY CLUSTERED,
	doc_id                  INT NOT NULL,
	doc_type_id             TINYINT NOT NULL CONSTRAINT [CH_RawMaterialInvoice_doc_type_id] CHECK(doc_type_id = 1),
	invoice_name            VARCHAR(30) NOT NULL,
	invoice_dt              DATE NOT NULL,
	dt                      DATETIME2(0) NOT NULL,
	employee_id             INT NOT NULL,
	is_deleted              BIT NOT NULL CONSTRAINT [DF_RawMaterialInvoice_is_deleted] DEFAULT(0),
	ttn_name                VARCHAR(30) NULL,
	ttn_dt                  DATE NULL,
	sync_finance_dt         DATETIME2(0) NULL,
	sync_stuff_model        BIT NOT NULL CONSTRAINT [DF_RawMaterialInvoice_sync_stuff_model] DEFAULT(0),
	sync_service_income     BIT NOT NULL CONSTRAINT [DF_RawMaterialInvoice_sync_service_income] DEFAULT(0),
	set_file_dt             DATETIME2(0) NULL,
	file_ext_id             SMALLINT CONSTRAINT [FK_RawMaterialInvoice_file_ext_id] FOREIGN KEY REFERENCES RefBook.FileExt(file_ext_id) NULL,
	CONSTRAINT [FK_RawMaterialInvoice_doc_id_doc_type_id] FOREIGN KEY(doc_type_id, doc_id) REFERENCES Documents.DocumentID(doc_type_id, doc_id)
)
GO

CREATE UNIQUE NONCLUSTERED INDEX [UQ_RawMaterialInvoice_rmi_id_invoice_name] ON Material.RawMaterialInvoice(doc_id, invoice_name, invoice_dt) WHERE is_deleted = 
0
ON [Indexes]
GO