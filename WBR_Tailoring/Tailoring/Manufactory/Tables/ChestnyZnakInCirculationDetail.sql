CREATE TABLE [Manufactory].[ChestnyZnakInCirculationDetail]
(
	czicd_id     INT IDENTITY(1, 1) CONSTRAINT [PK_ChestnyZnakInCirculationDetail] PRIMARY KEY CLUSTERED NOT NULL,
	czic_id      INT CONSTRAINT [FK_ChestnyZnakInCirculationDetail_czic_id] FOREIGN KEY REFERENCES Manufactory.ChestnyZnakInCirculation(czic_id) NOT NULL,
	oczdi_id     INT CONSTRAINT [FK_ChestnyZnakInCirculationDetail_oczdi_id] FOREIGN KEY REFERENCES Manufactory.OrderChestnyZnakDetailItem(oczdi_id) NOT NULL
)

GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_ChestnyZnakInCirculationDetail_oczdi_id] ON Manufactory.ChestnyZnakInCirculationDetail(oczdi_id) ON [Indexes]