CREATE TABLE [Manufactory].[ChestnyZnakOutCirculationDetail]
(
	czocd_id          INT IDENTITY(1, 1) CONSTRAINT [PK_ChestnyZnakOutCirculationDetail] PRIMARY KEY CLUSTERED NOT NULL,
	czoc_id            INT CONSTRAINT [FK_ChestnyZnakOutCirculationDetail_czco_id] FOREIGN KEY REFERENCES Manufactory.ChestnyZnakOutCirculation(czoc_id) NOT NULL,
	oczdi_id           INT CONSTRAINT [FK_ChestnyZnakOutCirculationDetail_oczdi_id] FOREIGN KEY REFERENCES Manufactory.OrderChestnyZnakDetailItem(oczdi_id) NOT NULL,
	price_with_vat     NUMERIC(9, 2) NOT NULL
)

GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_ChestnyZnakOutCirculationDetail_fiscal_dt_oczdi_id] ON Manufactory.ChestnyZnakOutCirculationDetail(czoc_id, oczdi_id) ON [Indexes]