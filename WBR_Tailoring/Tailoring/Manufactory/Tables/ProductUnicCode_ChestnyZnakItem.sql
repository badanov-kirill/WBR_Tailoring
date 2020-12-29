CREATE TABLE [Manufactory].[ProductUnicCode_ChestnyZnakItem]
(
	product_unic_code     INT CONSTRAINT [FK_ProductUnicCode_ChestnyZnakItem_product_unic_code] FOREIGN KEY REFERENCES Manufactory.ProductUnicCode(product_unic_code) NOT NULL,
	oczdi_id              INT CONSTRAINT [FK_ProductUnicCode_ChestnyZnakItem_oczd_id] FOREIGN KEY REFERENCES Manufactory.OrderChestnyZnakDetailItem(oczdi_id) NOT NULL,
	CONSTRAINT [PK_ProductUnicCode_ChestnyZnakItem] PRIMARY KEY CLUSTERED(product_unic_code)
)

GO 
CREATE UNIQUE NONCLUSTERED INDEX [UQ_ProductUnicCode_ChestnyZnakItem_oczdi_id] ON Manufactory.ProductUnicCode_ChestnyZnakItem(oczdi_id) ON [Indexes]