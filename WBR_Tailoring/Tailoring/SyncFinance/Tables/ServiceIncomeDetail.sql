CREATE TABLE [SyncFinance].[ServiceIncomeDetail]
(
	doc_id              INT CONSTRAINT [FK_ServiceIncomeDetail_doc_id] FOREIGN KEY REFERENCES SyncFinance.ServiceIncome(doc_id) NOT NULL,
	rmt_id              INT CONSTRAINT [FK_ServiceIncomeDetail_rmt_id] FOREIGN KEY REFERENCES Material.RawMaterialType(rmt_id) NOT NULL,
	nds                 TINYINT NOT NULL,
	amount_with_nds     DECIMAL(9, 2) NOT NULL,
	CONSTRAINT [PK_SyncFinance_ServiceIncomeDetail] PRIMARY KEY CLUSTERED(doc_id, rmt_id, nds)
)
