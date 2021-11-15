CREATE TABLE [dbo].[DataTypes]
(
	data_type_id SMALLINT IDENTITY(1, 1) CONSTRAINT [PK_DataTypes] PRIMARY KEY CLUSTERED NOT NULL,
	data_type_name VARCHAR(100) NOT NULL
)

GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_DataTypes_name]
    ON dbo.DataTypes(data_type_name ASC)
    ON [Indexes];