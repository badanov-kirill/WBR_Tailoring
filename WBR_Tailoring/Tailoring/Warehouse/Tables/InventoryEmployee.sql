CREATE TABLE [Warehouse].[InventoryEmployee]
(
	inventory_id     INT CONSTRAINT [FK_InventoryEmployee_inventory_id] FOREIGN KEY REFERENCES Warehouse.Inventory(inventory_id) NOT NULL,
	employee_id      INT NOT NULL,
	CONSTRAINT [PK_InventoryEmployee] PRIMARY KEY CLUSTERED(inventory_id, employee_id)
)
