﻿CREATE TABLE [Manufactory].[ChestnyZnakReturnCirculationDetailFail]
(
	czrcdf_id          INT IDENTITY(1, 1) CONSTRAINT [PK_ChestnyZnakReturnCirculationDetailFail] PRIMARY KEY CLUSTERED NOT NULL,
	czrc_id            INT CONSTRAINT [FK_ChestnyZnakReturnCirculationDetailFail_czco_id] FOREIGN KEY REFERENCES Manufactory.ChestnyZnakReturnCirculation(czrc_id) NOT NULL,
	gtin01             VARCHAR(14) NULL,
	serial21           NVARCHAR(20) NULL,
	price_with_vat     NUMERIC(9, 2) NOT NULL
)

GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_ChestnyZnakReturnCirculationDetailFail_fiscal_dt_gtin01_serial21] ON Manufactory.ChestnyZnakReturnCirculationDetailFail(czrc_id, gtin01, serial21) 
ON [Indexes]