CREATE TABLE [Ozon].[AttributesGroups]
(
	oag_id       INT IDENTITY(1, 1) CONSTRAINT [PK_AttributesGroups] PRIMARY KEY CLUSTERED NOT NULL,
	oag_name     VARCHAR(100) NOT NULL
)

GO
CREATE UNIQUE NONCLUSTERED INDEX [UX_AttributesGroups_oag_name] ON Ozon.AttributesGroups(oag_name) ON [Indexes];