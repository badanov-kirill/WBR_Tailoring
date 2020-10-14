CREATE TABLE [Products].[PatternSizeName]
(
	psn_id       INT IDENTITY(1, 1) CONSTRAINT [PK_PatternSizeName] PRIMARY KEY CLUSTERED NOT NULL,
	psn_name     VARCHAR(25) NOT NULL
)

GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_PatternSizeName_psn_name] ON Products.PatternSizeName(psn_name) ON [Indexes]