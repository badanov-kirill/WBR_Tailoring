CREATE TABLE [Warehouse].[InventoryStoragePlace]
(
	inventory_id     INT CONSTRAINT [FK_InventoryStoragePlace_inventory_id] FOREIGN KEY REFERENCES Warehouse.Inventory(inventory_id) NOT NULL,
	place_id      INT CONSTRAINT [FK_InventoryStoragePlace_place_id] FOREIGN KEY REFERENCES Warehouse.StoragePlace(place_id) NOT NULL,
	CONSTRAINT [PK_InventoryStoragePlace] PRIMARY KEY CLUSTERED(inventory_id, place_id)
)