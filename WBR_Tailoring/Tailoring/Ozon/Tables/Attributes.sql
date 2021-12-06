CREATE TABLE [Ozon].[Attributes]
(
	attribute_id        BIGINT CONSTRAINT [PK_OzonAttributes] PRIMARY KEY CLUSTERED NOT NULL,
	attribute_name      VARCHAR(50) NOT NULL,
	attribute_descr     VARCHAR(900) NULL,
	data_type_id        SMALLINT CONSTRAINT [FK_OzonAttributes_data_type_id] FOREIGN KEY REFERENCES dbo.DataTypes(data_type_id) NULL,
	oag_id              INT CONSTRAINT [FK_OzonAttributes_oag_id] FOREIGN KEY REFERENCES Ozon.AttributesGroups(oag_id) NULL,
	is_collection       BIT NOT NULL,
	dictionary_id       INT NULL,
	is_used             BIT NOT NULL
)
