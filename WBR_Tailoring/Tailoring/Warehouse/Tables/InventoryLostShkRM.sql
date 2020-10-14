﻿CREATE TABLE [Warehouse].[InventoryLostShkRM]
(
	ils_id                         INT IDENTITY(1, 1) CONSTRAINT [PK_InventoryLostShkRM] PRIMARY KEY CLUSTERED NOT NULL,
	inventory_id                   INT CONSTRAINT [FK_InventoryLostShkRM_inventory_id] FOREIGN KEY REFERENCES Warehouse.Inventory(inventory_id) NOT NULL,
	shkrm_id                       INT CONSTRAINT [FK_InventoryLostShkRm_shkrm_id] FOREIGN KEY REFERENCES Warehouse.SHKRawMaterial(shkrm_id) NOT NULL,
	place_id                       INT CONSTRAINT [FK_InventoryLostShkRM_place_id] FOREIGN KEY REFERENCES Warehouse.StoragePlace(place_id) NOT NULL,
	okei_id                        INT CONSTRAINT [FK_InventoryLostShkRM_okei_id] FOREIGN KEY REFERENCES Qualifiers.OKEI(okei_id) NOT NULL,
	qty                            DECIMAL(9, 3) CONSTRAINT [CH_InventoryLostShkRM_qty] CHECK(qty > 0) NOT NULL,
	stor_unit_residues_okei_id     INT CONSTRAINT [FK_InventoryLostShkRM_stor_unit_residues_okei_id] FOREIGN KEY REFERENCES Qualifiers.OKEI(okei_id) NOT NULL,
	stor_unit_residues_qty         DECIMAL(9, 3) CONSTRAINT [CH_InventoryLostShkRM_stor_unit_res_qty] CHECK(stor_unit_residues_qty > 0) NOT NULL,
	amount                         DECIMAL(19, 8) CONSTRAINT [CH_InventoryLostShkRM_amount] CHECK(amount >= 0) NOT NULL,
	employee_id                    INT NOT NULL,
	dt                             DATETIME2(0) NOT NULL
)

GO 
CREATE UNIQUE NONCLUSTERED INDEX [UQ_InventoryLostShkRM_inventory_id_shkrm_id] ON Warehouse.InventoryLostShkRM(inventory_id,shkrm_id) ON [Indexes]

GO 
CREATE UNIQUE NONCLUSTERED INDEX [UQ_InventoryLostShkRM_shkrm_id] ON Warehouse.InventoryLostShkRM(shkrm_id) ON [Indexes]