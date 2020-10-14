CREATE TABLE [Material].[RawMaterialInvoiceRelationDetail]
(
	rmid_id         INT NOT NULL CONSTRAINT [FK_RawMaterialRelationDetail_shkrm_id] FOREIGN KEY REFERENCES Material.RawMaterialIncomeDetail(rmid_id),
	rm_invd_id       INT NOT NULL CONSTRAINT [FK_RawMaterialInvoiceDetail_rmid_id] FOREIGN KEY REFERENCES Material.RawMaterialInvoiceDetail(rmid_id),
	amount          DECIMAL(19, 8) NOT NULL,
	doc_id          INT NOT NULL,
	doc_type_id     TINYINT NOT NULL,
	CONSTRAINT [PK_RawMaterialInvoiceRelationDetail] PRIMARY KEY CLUSTERED(rmid_id, rm_invd_id),
	CONSTRAINT [FK_RawMaterialInvoiceRelationDetail_doc_id_doc_type_id] FOREIGN KEY(doc_type_id, doc_id) REFERENCES Documents.DocumentID(doc_type_id, doc_id)
)
GO