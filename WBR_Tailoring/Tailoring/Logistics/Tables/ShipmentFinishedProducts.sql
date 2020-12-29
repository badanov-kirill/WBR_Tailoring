CREATE TABLE [Logistics].[ShipmentFinishedProducts]
(
	sfp_id                   INT IDENTITY(1, 1) CONSTRAINT [PK_ShipmentFinishedProducts] PRIMARY KEY CLUSTERED NOT NULL,
	src_office_id            INT CONSTRAINT [FK_ShipmentFinishedProducts_src_office_id] FOREIGN KEY REFERENCES Settings.OfficeSetting (office_id) NOT NULL,
	seal1                    VARCHAR(20) NULL,
	seal2                    VARCHAR(20) NULL,
	employee_id              INT NOT NULL,
	dt                       DATETIME2(0) NOT NULL,
	vehicle_id               INT CONSTRAINT [FK_ShipmentFinishedProducts_vehicle_id] FOREIGN KEY REFERENCES Logistics.Vehicle(vehicle_id) NULL,
	driver_id                INT CONSTRAINT [FK_ShipmentFinishedProducts_driver_id] FOREIGN KEY REFERENCES Logistics.Driver(driver_id) NULL,
	towed_vehicle_id         INT CONSTRAINT [FK_ShipmentFinishedProducts_towed_vehicle_id] FOREIGN KEY REFERENCES Logistics.Vehicle(vehicle_id) NULL,
	complite_employee_id     INT NULL,
	complite_dt              DATETIME2(0) NULL,
	is_deleted               BIT NOT NULL,
	create_employee_id       INT NOT NULL,
	create_dt                DATETIME2(0) NOT NULL,
	rv                       ROWVERSION NOT NULL,
	plan_dt                  DATE NULL,
	close_planing_dt         DATETIME2(0) NULL,
	order_wb                 INT NULL,
	supplier_id				 INT CONSTRAINT [FK_ShipmentFinishedProducts_supplier_id] FOREIGN KEY REFERENCES Suppliers.Supplier(supplier_id) NULL
)

GO 
CREATE UNIQUE NONCLUSTERED INDEX [UQ_ShipmentFinishedProducts_order_wb] ON Logistics.ShipmentFinishedProducts(order_wb) WHERE order_wb IS NOT NULL ON [Indexes]