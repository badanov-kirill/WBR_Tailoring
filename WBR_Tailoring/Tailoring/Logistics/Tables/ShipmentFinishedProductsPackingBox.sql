CREATE TABLE [Logistics].[ShipmentFinishedProductsPackingBox]
(
	sfpd_id            INT IDENTITY(1, 1) CONSTRAINT [PK_ShipmentFinishedProductsPackingBox] PRIMARY KEY CLUSTERED NOT NULL,
	sfp_id             INT CONSTRAINT [FK_ShipmentFinishedProductsPackingBox_sfp_id] FOREIGN KEY REFERENCES Logistics.ShipmentFinishedProducts(sfp_id) NOT NULL,
	packing_box_id     INT CONSTRAINT [FK_ShipmentFinishedProductsPackingBox_packing_box_id] FOREIGN KEY REFERENCES Logistics.PackingBox(packing_box_id) NOT NULL,
	dt                 DATETIME2(0) NOT NULL,
	employee_id        INT NOT NULL
)

GO 
CREATE UNIQUE NONCLUSTERED INDEX [UQ_ShipmentFinishedProductsPackingBox_sfp_id_packing_box_id] ON Logistics.ShipmentFinishedProductsPackingBox(sfp_id, packing_box_id) 
ON [Indexes]

GO 
CREATE UNIQUE NONCLUSTERED INDEX [UQ_ShipmentFinishedProductsPackingBox_packing_box_id] ON Logistics.ShipmentFinishedProductsPackingBox(packing_box_id) ON 
[Indexes]