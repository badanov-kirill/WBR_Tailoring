CREATE TABLE [Warehouse].[InventoryType]
(
	it_id       TINYINT IDENTITY(1, 1) CONSTRAINT [PK_InventoryType] PRIMARY KEY CLUSTERED NOT NULL,
	it_name     VARCHAR(50) NOT NULL
)
