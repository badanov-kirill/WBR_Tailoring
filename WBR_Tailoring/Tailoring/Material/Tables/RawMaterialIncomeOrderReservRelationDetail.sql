CREATE TABLE [Material].[RawMaterialIncomeOrderReservRelationDetail]
(
	rmid_id         INT NOT NULL CONSTRAINT [FK_RawMaterialIncomeOrderReservRelationDetail_rmid_id] FOREIGN KEY REFERENCES Material.RawMaterialIncomeDetail(rmid_id),
	rmodr_id        INT NOT NULL CONSTRAINT [FK_RawMaterialIncomeOrderReservRelationDetail_rmodr_id] FOREIGN KEY REFERENCES Suppliers.RawMaterialOrderDetailFromReserv(rmodr_id),
	spcvc_id        INT NOT NULL CONSTRAINT [FK_RawMaterialIncomeOrderRelationDetail_spcvc_id] FOREIGN KEY REFERENCES Planing.SketchPlanColorVariantCompleting(spcvc_id),
	okei_id         INT NOT NULL CONSTRAINT [FK_RawMaterialIncomeOrderReservRelationDetail_okei_id] FOREIGN KEY REFERENCES Qualifiers.OKEI(okei_id),
	quantity        DECIMAL(9, 3) NOT NULL,
	doc_id          INT NOT NULL,
	doc_type_id     TINYINT NOT NULL,
	operation_num	INT NOT NULL,
	CONSTRAINT [PK_RawMaterialIncomeOrderReservRelationDetail] PRIMARY KEY CLUSTERED(rmid_id, rmodr_id),
	CONSTRAINT [FK_RawMaterialIncomeOrderReservRelationDetail_doc_id_doc_type_id] FOREIGN KEY(doc_type_id, doc_id) REFERENCES Documents.DocumentID(doc_type_id, doc_id)
)	
GO