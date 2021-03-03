CREATE TABLE [Manufactory].[ChestnyZnakInCirculationOutDetail]
(
	czicod_id          INT IDENTITY(1, 1) CONSTRAINT [PK_ChestnyZnakInCirculationOutDetail] PRIMARY KEY CLUSTERED NOT NULL,
	czco_id            INT CONSTRAINT [FK_ChestnyZnakInCirculationOutDetail_czco_id] FOREIGN KEY REFERENCES Manufactory.ChestnyZnakInCirculationOut(czco_id) NOT NULL,
	oczdi_id           INT CONSTRAINT [FK_ChestnyZnakInCirculationOutDetail_oczdi_id] FOREIGN KEY REFERENCES Manufactory.OrderChestnyZnakDetailItem(oczdi_id) NOT NULL,
	cr_id              INT CONSTRAINT [FK_ChestnyZnakInCirculationOutDetail_cr_id] FOREIGN KEY REFERENCES RefBook.CashReg(cr_id) NOT NULL,
	fa_id              INT CONSTRAINT [FK_ChestnyZnakInCirculationOutDetail_fa_id] FOREIGN KEY REFERENCES RefBook.FiscalAccumulator(fa_id) NOT NULL,
	fiscal_dt          DATE NOT NULL,
	price_with_vat     NUMERIC(9, 2) NOT NULL
)

GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_ChestnyZnakInCirculationOutDetail_oczdi_id] ON Manufactory.ChestnyZnakInCirculationOutDetail(oczdi_id) ON [Indexes]