CREATE TABLE [Synchro].[UploadBuh_Doc]
(
	doc_id                    INT NOT NULL,
	upload_doc_type_id        TINYINT NOT NULL,
	suppliercontract_code     VARCHAR(9) NULL,
	supplier_id               INT CONSTRAINT [FK_UploadBuh_Doc_supplier_id] FOREIGN KEY REFERENCES Suppliers.Supplier (supplier_id) NULL,
	is_deleted                BIT NOT NULL,
	rv                        ROWVERSION NOT NULL,
	office_id                 INT CONSTRAINT [FK_UploadBuh_Doc_office_id] FOREIGN KEY REFERENCES Settings.OfficeSetting(office_id) NULL,
	doc_dt                    DATETIME2(0) NOT NULL,
	currency_id               INT NULL,
	CONSTRAINT [PK_UploadBuh_Doc] PRIMARY KEY CLUSTERED(doc_id, upload_doc_type_id)
)
