CREATE TABLE [Material].[RawMaterialIncomeOrderToSupplier]
(
	doc_id                  INT NOT NULL,
	doc_type_id             TINYINT CONSTRAINT [CH_RawMaterialIncomeOrderToSupplier_doc_type_id] CHECK(doc_type_id = 1) NOT NULL,
	ots_id INT CONSTRAINT [FK_RawMaterialIncomeOrderToSupplier_ots_id] FOREIGN KEY REFERENCES Material.OrderToSupplier(ots_id) NOT NULL,
	CONSTRAINT [FK_RawMaterialIncomeOrderToSupplier_doc_id_doc_type_id] FOREIGN KEY(doc_type_id, doc_id) REFERENCES Documents.DocumentID(doc_type_id, doc_id),
	CONSTRAINT [PK_RawMaterialIncomeOrderToSupplier] PRIMARY KEY CLUSTERED (doc_type_id, doc_id, ots_id) 
)
