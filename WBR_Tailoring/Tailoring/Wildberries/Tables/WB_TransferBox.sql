CREATE TABLE [Wildberries].[WB_TransferBox]
(
	wbtb_id            INT IDENTITY(1, 1) CONSTRAINT [PK_WB_TransferBox] PRIMARY KEY CLUSTERED NOT NULL,
	box_name           VARCHAR(20) NOT NULL,
	sfp_id             INT CONSTRAINT [FK_WB_TransferBox_sfp_id] FOREIGN KEY REFERENCES Logistics.ShipmentFinishedProducts(sfp_id) NOT NULL,
	packing_box_id     INT CONSTRAINT [FK_WB_TransferBox_packing_box_id] FOREIGN KEY REFERENCES Logistics.PackingBox(packing_box_id) NOT NULL,
	dt                 DATETIME2(0) NOT NULL,
	employee_id        INT NOT NULL
)

GO 
CREATE UNIQUE NONCLUSTERED INDEX [UQ_WB_TransferBox_box_name] ON Wildberries.WB_TransferBox(box_name) ON [Indexes]

GO
CREATE NONCLUSTERED INDEX [IX_TransferBox_sfp_id] ON Wildberries.WB_TransferBox(sfp_id) ON [Indexes]

GO 
CREATE UNIQUE NONCLUSTERED INDEX [UQ_WB_TransferBox_packing_box_id] ON Wildberries.WB_TransferBox(packing_box_id) ON [Indexes]
