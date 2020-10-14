CREATE TABLE [Synchro].[ProductsForEAN]
(
	pants_id       INT CONSTRAINT [FK_ProductsForEAN_pants_id] FOREIGN KEY REFERENCES Products.ProdArticleNomenclatureTechSize(pants_id) NOT NULL,
	dt_create      DATETIME2(0) NULL,
	dt_publish     DATETIME2(0) NULL,
	CONSTRAINT [PK_ProductsForEAN] PRIMARY KEY CLUSTERED(pants_id)
)

GO
CREATE INDEX [IX_ProductsForEAN_pants_id] ON Synchro.ProductsForEAN(pants_id) WHERE dt_create IS NULL ON [Indexes]

GO
CREATE INDEX [IX_ProductsForEAN_pants_id_dt_publish] ON Synchro.ProductsForEAN(pants_id) WHERE dt_publish IS NULL ON [Indexes]