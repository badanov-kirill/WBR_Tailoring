CREATE TABLE [Logistics].[TransferBoxDetail]
(
	transfer_box_id       BIGINT CONSTRAINT [FK_TransferBoxDetail_transfer_box_id] FOREIGN KEY REFERENCES Logistics.TransferBox(transfer_box_id) NOT NULL,
	product_unic_code     INT CONSTRAINT [FK_TransferBoxDetail_product_unic_code] FOREIGN KEY REFERENCES Manufactory.ProductUnicCode(product_unic_code) NOT NULL,
	rv                    ROWVERSION NOT NULL,
	CONSTRAINT [PK_TransferBoxDetail] PRIMARY KEY CLUSTERED(transfer_box_id, product_unic_code)
)

GO 
CREATE UNIQUE NONCLUSTERED INDEX [UQ_TransferBoxDetail_product_unic_code] ON Logistics.TransferBoxDetail(product_unic_code) ON [Indexes]
