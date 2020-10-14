CREATE TABLE [Warehouse].[StoragePlaceType]
(
	place_type_id       INT CONSTRAINT [PK_StoragePlaceType] PRIMARY KEY CLUSTERED NOT NULL,
	place_type_name     VARCHAR(100) NOT NULL
)