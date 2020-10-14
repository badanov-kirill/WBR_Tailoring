CREATE TABLE [SyncFinance].[MaterialStuffSupplyDetail]
(
	doc_id                  INT CONSTRAINT [FK_MaterialStuffSupplyDetail_doc_id] FOREIGN KEY REFERENCES SyncFinance.MaterialStuffSupply(doc_id) NOT NULL,
	stuff_shk_id            INT NOT NULL,
	stuff_model_id          INT NOT NULL,
	manufactured_number     VARCHAR(20) NULL,
	nds                     TINYINT NOT NULL,
	amount_with_nds         DECIMAL(9, 2) NOT NULL,
	okei_id                 INT CONSTRAINT [FK_MaterialStuffSupplyDetail_okei_id] FOREIGN KEY REFERENCES Qualifiers.OKEI(okei_id) NOT NULL,
	CONSTRAINT [PK_MaterialStuffSupplyDetail_ServiceIncomeDetail] PRIMARY KEY CLUSTERED(doc_id, stuff_shk_id)
)
