CREATE TABLE [Material].[RawMaterialIncomeExpenseRelationDetail]
(
	rmid_id         INT NOT NULL CONSTRAINT [FK_RawMaterialIncomeExpenseRelationDetail_rmid_id] FOREIGN KEY REFERENCES Material.RawMaterialIncomeDetail(rmid_id),
	rmie_id         INT NOT NULL CONSTRAINT [FK_RawMaterialIncomeExpenseRelationDetail_rmie_id] FOREIGN KEY REFERENCES Material.RawMaterialIncomeExpense(rmie_id),
	amount          DECIMAL(19, 8) NOT NULL,
	doc_id          INT NOT NULL,
	doc_type_id     TINYINT NOT NULL,
	CONSTRAINT [PK_RawMaterialIncomeExpenseRelationDetail] PRIMARY KEY CLUSTERED(rmid_id, rmie_id),
	CONSTRAINT [FK_RawMaterialIncomeExpenseRelationDetail_doc_id_doc_type_id] FOREIGN KEY(doc_type_id, doc_id) REFERENCES Documents.DocumentID(doc_type_id, doc_id)
)
GO