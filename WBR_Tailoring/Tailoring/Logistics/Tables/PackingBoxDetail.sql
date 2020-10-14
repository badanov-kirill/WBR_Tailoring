CREATE TABLE [Logistics].[PackingBoxDetail]
(
	pbd_id                INT IDENTITY(1, 1) CONSTRAINT [PK_PackingBoxDetail] PRIMARY KEY CLUSTERED NOT NULL,
	packing_box_id        INT CONSTRAINT [FK_PackingBoxDetail_packing_box_id] FOREIGN KEY REFERENCES Logistics.PackingBox(packing_box_id) NOT NULL,
	product_unic_code     INT CONSTRAINT [FK_PackingBoxDetail_product_unic_code] FOREIGN KEY REFERENCES Manufactory.ProductUnicCode(product_unic_code) NOT NULL,
	dt                    DATETIME2(0) NOT NULL,
	employee_id           INT NOT NULL,
	barcode				  VARCHAR(13) NOT NULL
)

GO 
CREATE UNIQUE NONCLUSTERED INDEX [UQ_PackingBoxDetail_product_unic_code] ON Logistics.PackingBoxDetail(product_unic_code) ON [Indexes]

GO 
CREATE UNIQUE NONCLUSTERED INDEX [UQ_PackingBoxDetail_packing_box_id_product_unic_code] ON Logistics.PackingBoxDetail(packing_box_id, product_unic_code) ON 
[Indexes]