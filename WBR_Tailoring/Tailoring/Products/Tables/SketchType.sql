CREATE TABLE [Products].[SketchType]
(
	st_id       INT CONSTRAINT [PK_SketchType] PRIMARY KEY CLUSTERED NOT NULL,
	st_name     VARCHAR(50) NOT NULL
)

GO

CREATE UNIQUE NONCLUSTERED INDEX [UQ_SketchType_st_name] ON Products.SketchType(st_name) ON [Indexes]
GO