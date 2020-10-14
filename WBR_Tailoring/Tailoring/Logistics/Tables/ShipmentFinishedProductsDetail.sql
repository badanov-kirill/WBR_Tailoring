CREATE TABLE [Logistics].[ShipmentFinishedProductsDetail]
(
	sfpd_id             INT IDENTITY(1, 1) CONSTRAINT [PK_ShipmentFinishedProductsDetail] PRIMARY KEY CLUSTERED NOT NULL,
	sfp_id              INT CONSTRAINT [FK_ShipmentFinishedProductsDetail_sfp_id] FOREIGN KEY REFERENCES Logistics.ShipmentFinishedProducts(sfp_id) NOT NULL,
	transfer_box_id     BIGINT CONSTRAINT [FK_ShipmentFinishedProductsDetail_transfer_box_id] FOREIGN KEY REFERENCES Logistics.TransferBox(transfer_box_id) NOT NULL,
	dt                  DATETIME2(0) NOT NULL,
	employee_id         INT NOT NULL
)

GO 
CREATE UNIQUE NONCLUSTERED INDEX [UQ_ShipmentFinishedProductsDetail_sfp_id_transfer_box_id] ON Logistics.ShipmentFinishedProductsDetail(sfp_id, transfer_box_id) ON [Indexes]

GO 
CREATE UNIQUE NONCLUSTERED INDEX [UQ_ShipmentFinishedProductsDetail_transfer_box_id] ON Logistics.ShipmentFinishedProductsDetail(transfer_box_id) ON [Indexes]