CREATE TABLE [Manufactory].[ProductUniqDataMatrixProductUnic]
(
	product_uniq_data_martix_id     INT CONSTRAINT [PK_ProductUniqDataMatrixProductUnic] PRIMARY KEY CLUSTERED NOT NULL,
	product_unic_code               INT CONSTRAINT [FK_ProductUniqDataMatrixProductUnic_product_unic_code] FOREIGN KEY REFERENCES Manufactory.ProductUnicCode(product_unic_code) NOT NULL
)

GO 
CREATE UNIQUE NONCLUSTERED INDEX [UQ_ProductUniqDataMatrixProductUnic_product_unic_code] ON Manufactory.ProductUniqDataMatrixProductUnic(product_unic_code) 
INCLUDE(product_uniq_data_martix_id) ON [Indexes]