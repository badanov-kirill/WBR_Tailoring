CREATE TABLE [Products].[SketchLogicStatusDict]
(
	sls_id             TINYINT IDENTITY(1, 1) CONSTRAINT [PK_SketchLogicStatusDict] PRIMARY KEY CLUSTERED(sls_id) NOT NULL,
	sls_name           VARCHAR(50) NOT NULL,
	sls_short_name     VARCHAR(50) NULL
)

GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_SketchLogicStatusDict_sls_name] ON Products.SketchLogicStatusDict(sls_name) ON [Indexes]
GO