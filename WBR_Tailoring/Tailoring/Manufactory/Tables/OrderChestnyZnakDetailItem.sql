CREATE TABLE [Manufactory].[OrderChestnyZnakDetailItem]
(
	oczdi_id      INT IDENTITY(1, 1) CONSTRAINT [PK_OrderChestnyZnakDetailItem] PRIMARY KEY CLUSTERED NOT NULL,
	oczd_id       INT CONSTRAINT [FK_OrderChestnyZnakDetailItem_ocz_id] FOREIGN KEY REFERENCES Manufactory.OrderChestnyZnakDetail(oczd_id) NOT NULL,
	code          NVARCHAR(200) NOT NULL,
	gtin01        VARCHAR(14) NULL,
	serial21      NVARCHAR(20) NULL,
	intrnal91     NVARCHAR(10) NULL,
	intrnal92     NVARCHAR(90) NULL,
	block_id      INT CONSTRAINT [FK_OrderChestnyZnakDetailItem_block_id] FOREIGN KEY REFERENCES Manufactory.OrderChestnyZnakBlock(block_id) NULL,
)

GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_OrderChestnyZnakDetailItem_oczd_id_gtin01_serial21] ON Manufactory.OrderChestnyZnakDetailItem(oczd_id, serial21) 
WHERE (gtin01 IS NOT NULL AND serial21 IS NOT NULL) ON [Indexes]