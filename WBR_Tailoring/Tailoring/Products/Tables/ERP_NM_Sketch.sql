CREATE TABLE [Products].[ERP_NM_Sketch]
(
	nm_id       INT CONSTRAINT [PK_ERP_NM] PRIMARY KEY CLUSTERED,
	imt_id      INT NOT NULL,
	sa          VARCHAR(36) NOT NULL
)

GO

CREATE NONCLUSTERED INDEX [IX_ERP_NM_Sketch_imt_id]
ON Products.ERP_NM_Sketch (imt_id) INCLUDE (nm_id) ON [Indexes]