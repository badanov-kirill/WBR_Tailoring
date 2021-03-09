CREATE TABLE [Manufactory].[ChestnyZnakReturnCirculationDetail]
(
	czrcd_id          INT IDENTITY(1, 1) CONSTRAINT [PK_ChestnyZnakReturnCirculationDetail] PRIMARY KEY CLUSTERED NOT NULL,
	czrc_id            INT CONSTRAINT [FK_ChestnyZnakReturnCirculationDetail_czco_id] FOREIGN KEY REFERENCES Manufactory.ChestnyZnakReturnCirculation(czrc_id) NOT NULL,
	oczdi_id           INT CONSTRAINT [FK_ChestnyZnakReturnCirculationDetail_oczdi_id] FOREIGN KEY REFERENCES Manufactory.OrderChestnyZnakDetailItem(oczdi_id) NOT NULL,
	fiscal_num         INT NOT NULL,
	cr_id              INT CONSTRAINT [FK_ChestnyZnakReturnCirculationDetail_cr_id] FOREIGN KEY REFERENCES RefBook.CashReg(cr_id) NOT NULL,
	fa_id              INT CONSTRAINT [FK_ChestnyZnakReturnCirculationDetail_fa_id] FOREIGN KEY REFERENCES RefBook.FiscalAccumulator(fa_id) NOT NULL,
	fiscal_dt          DATE NOT NULL,
	price_with_vat     NUMERIC(9, 2) NOT NULL
)

GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_ChestnyZnakReturnCirculationDetail_fiscal_dt_oczdi_id] ON Manufactory.ChestnyZnakReturnCirculationDetail(fiscal_dt, oczdi_id, fiscal_num) ON [Indexes]