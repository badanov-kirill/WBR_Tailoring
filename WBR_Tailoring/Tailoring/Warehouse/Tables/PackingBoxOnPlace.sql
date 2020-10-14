CREATE TABLE [Warehouse].[PackingBoxOnPlace]
(
	packing_box_id     INT CONSTRAINT [FK_PackingBoxOnPlace_packing_box_id] FOREIGN KEY REFERENCES Logistics.PackingBox(packing_box_id) NOT NULL,
	place_id           INT CONSTRAINT [FK_PackingBoxOnPlace_place_id] FOREIGN KEY REFERENCES Warehouse.StoragePlace(place_id) NOT NULL,
	dt                 DATETIME2(0) NOT NULL,
	employee_id        INT NOT NULL,
	rv                 ROWVERSION NOT NULL,
	CONSTRAINT [PK_PackingBoxOnPlace] PRIMARY KEY CLUSTERED(packing_box_id ASC)
)
