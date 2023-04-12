CREATE TABLE [Synchro].[ProductsForEAN] (
    [pants_id]      INT           NOT NULL,
    [dt_create]     DATETIME2 (0) NULL,
    [dt_publish]    DATETIME2 (0) NULL,
    [fabricator_id] INT           NOT NULL,
    CONSTRAINT [PK_ProductsForEAN] PRIMARY KEY CLUSTERED ([pants_id] ASC, [fabricator_id] ASC),
    CONSTRAINT [FK_ProductsForEAN_fabricator_id] FOREIGN KEY ([fabricator_id]) REFERENCES [Settings].[Fabricators] ([fabricator_id]),
    CONSTRAINT [FK_ProductsForEAN_pants_id] FOREIGN KEY ([pants_id]) REFERENCES [Products].[ProdArticleNomenclatureTechSize] ([pants_id])
);



GO
CREATE INDEX [IX_ProductsForEAN_pants_id] ON Synchro.ProductsForEAN(pants_id) WHERE dt_create IS NULL ON [Indexes]

GO
CREATE INDEX [IX_ProductsForEAN_pants_id_dt_publish] ON Synchro.ProductsForEAN(pants_id) WHERE dt_publish IS NULL ON [Indexes]