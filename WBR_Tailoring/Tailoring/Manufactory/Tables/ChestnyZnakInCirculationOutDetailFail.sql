CREATE TABLE [Manufactory].[ChestnyZnakInCirculationOutDetailFail]
(
	czicodf_id          INT IDENTITY(1, 1) CONSTRAINT [PK_ChestnyZnakInCirculationOutDetailFail] PRIMARY KEY CLUSTERED NOT NULL,
	czco_id            INT CONSTRAINT [FK_ChestnyZnakInCirculationOutDetailFail_czco_id] FOREIGN KEY REFERENCES Manufactory.ChestnyZnakInCirculationOut(czco_id) NOT NULL,
	gtin01        VARCHAR(14) NULL,
	serial21      NVARCHAR(20) NULL,
	cr_id              INT CONSTRAINT [FK_ChestnyZnakInCirculationOutDetailFail_cr_id] FOREIGN KEY REFERENCES RefBook.CashReg(cr_id) NOT NULL,
	fa_id              INT CONSTRAINT [FK_ChestnyZnakInCirculationOutDetailFail_fa_id] FOREIGN KEY REFERENCES RefBook.FiscalAccumulator(fa_id) NOT NULL,
	fiscal_dt          DATE NOT NULL,
	price_with_vat     NUMERIC(9, 2) NOT NULL
)

GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_ChestnyZnakInCirculationOutDetailFail_gtin01_serial21] ON Manufactory.ChestnyZnakInCirculationOutDetailFail(gtin01, serial21) ON [Indexes]