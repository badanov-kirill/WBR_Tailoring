CREATE TABLE [Material].[RawMaterialIncomeOrderRelationDetail]
(
	rmid_id         INT NOT NULL CONSTRAINT [FK_RawMaterialIncomeOrderRelationDetail_rmid_id] FOREIGN KEY REFERENCES Material.RawMaterialIncomeDetail(rmid_id),
	rmod_id         INT NOT NULL CONSTRAINT [FK_RawMaterialIncomeOrderRelationDetail_rmod_id] FOREIGN KEY REFERENCES Suppliers.RawMaterialOrderDetail(rmod_id),
	okei_id         INT NOT NULL CONSTRAINT [FK_RawMaterialIncomeOrderRelationDetail_okei_id] FOREIGN KEY REFERENCES Qualifiers.OKEI(okei_id),
	quantity        DECIMAL(9, 3) NOT NULL,
	doc_id          INT NOT NULL,
	doc_type_id     TINYINT NOT NULL,
	operation_num	INT NOT NULL,
	CONSTRAINT [PK_RawMaterialIncomeOrderRelationDetail] PRIMARY KEY CLUSTERED(rmid_id, rmod_id),
	CONSTRAINT [FK_RawMaterialIncomeOrderRelationDetail_doc_id_doc_type_id] FOREIGN KEY(doc_type_id, doc_id) REFERENCES Documents.DocumentID(doc_type_id, doc_id)
)	
GO