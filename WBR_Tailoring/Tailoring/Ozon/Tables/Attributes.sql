CREATE TABLE [Ozon].[Attributes]
(
	attribute_id INT CONSTRAINT [PK_Attributes] PRIMARY KEY CLUSTERED NOT NULL,
	attribute_name VARCHAR(50) NOT NULL,
	attribute_descr VARCHAR(500) NOT NULL
)
