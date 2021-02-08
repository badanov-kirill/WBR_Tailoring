CREATE TABLE [Logistics].[ShipmentFinishedProductsChestnyZnak]
(
	sfpcz_id        INT IDENTITY(1, 1) CONSTRAINT [PK_ShipmentFinishedProductsChestnyZnak] PRIMARY KEY CLUSTERED NOT NULL,
	sfp_id          INT CONSTRAINT [FK_ShipmentFinishedProductsChestnyZnak_sfp_id] FOREIGN KEY REFERENCES Logistics.ShipmentFinishedProducts(sfp_id) NOT NULL,
	oczdi_id        INT CONSTRAINT [FK_ShipmentFinishedProductsChestnyZnak_oczdi_id] FOREIGN KEY REFERENCES Manufactory.OrderChestnyZnakDetailItem(oczdi_id) NOT NULL,
	dt              DATETIME2(0) NOT NULL,
	employee_id     INT NOT NULL
)

GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_ShipmentFinishedProductsChestnyZnak_sfp_id_oczdi_id] ON Logistics.ShipmentFinishedProductsChestnyZnak(sfp_id, oczdi_id)