CREATE TABLE [Products].[AddedOptionType]
(
	ao_type_id       INT CONSTRAINT [PK_AddedOptionType] PRIMARY KEY CLUSTERED NOT NULL,
	ao_type_name     VARCHAR(100) NOT NULL
)

GO

CREATE UNIQUE NONCLUSTERED INDEX [UQ_AddedOptionType_ao_type_name] ON Products.AddedOptionType(ao_type_name) ON [Indexes]
GO