CREATE TABLE [Material].[RawMaterialIncomeOrder]
(
	rmio_id         INT NOT NULL IDENTITY(1, 1) CONSTRAINT [PK_RawMaterialIncomeOrder] PRIMARY KEY CLUSTERED,
	doc_id          INT NOT NULL,
	doc_type_id     TINYINT NOT NULL,
	rmo_id          INT NOT NULL CONSTRAINT [FK_RawMaterialIncome_rmo_id] FOREIGN KEY REFERENCES Suppliers.RawMaterialOrder(rmo_id),
	employee_id     INT NOT NULL,
	dt              DATETIME2(0) NOT NULL,
	CONSTRAINT [FK_RawMaterialIncomeOrder_doc_id_doc_type_id] FOREIGN KEY(doc_type_id, doc_id) REFERENCES Documents.DocumentID(doc_type_id, doc_id)
)
GO

CREATE UNIQUE NONCLUSTERED INDEX [UQ_RawMaterialIncomeOrder_doc_id_doc_type_id_rmo_id] ON Material.RawMaterialIncomeOrder(doc_id, doc_type_id, rmo_id)
ON [Indexes]
GO