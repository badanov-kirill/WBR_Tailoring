CREATE TABLE [Ozon].[Attributes]
(
	attribute_id INT CONSTRAINT [PK_Attributes] PRIMARY KEY CLUSTERED NOT NULL,
	attribute_name VARCHAR(50) NOT NULL,
	attribute_descr VARCHAR(500) NOT NULL,
	data_type_id SMALLINT CONSTRAINT [FK_OzonAttributes_data_type_id] FOREIGN KEY REFERENCES dbo.DataTypes(data_type_id) NULL,
	is_collection BIT NULL,
	dictionary_id INT NULL,
	group_id INT NULL,
	group_name VARCHAR(25) NULL,
)
