CREATE TABLE [Manufactory].[ChestnyZnakOutCirculationDetailFail]
(
	czocdf_id          INT IDENTITY(1, 1) CONSTRAINT [PK_ChestnyZnakOutCirculationDetailFail] PRIMARY KEY CLUSTERED NOT NULL,
	czoc_id            INT CONSTRAINT [FK_ChestnyZnakOutCirculationDetailFail_czco_id] FOREIGN KEY REFERENCES Manufactory.ChestnyZnakOutCirculation(czoc_id) NOT NULL,
	gtin01             VARCHAR(14) NULL,
	serial21           NVARCHAR(20) NULL,
	fiscal_num         INT NOT NULL,
	cr_id              INT CONSTRAINT [FK_ChestnyZnakOutCirculationDetailFail_cr_id] FOREIGN KEY REFERENCES RefBook.CashReg(cr_id) NOT NULL,
	fa_id              INT CONSTRAINT [FK_ChestnyZnakOutCirculationDetailFail_fa_id] FOREIGN KEY REFERENCES RefBook.FiscalAccumulator(fa_id) NOT NULL,
	fiscal_dt          DATE NOT NULL,
	price_with_vat     NUMERIC(9, 2) NOT NULL
)

GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_ChestnyZnakOutCirculationDetailFail_czoc_id_gtin01_serial21] ON Manufactory.ChestnyZnakOutCirculationDetailFail(fiscal_dt, gtin01, serial21, fiscal_num) 
ON [Indexes]