CREATE TABLE [Synchro].[ProductsForEAN2] (
    [pants_id]   INT           NOT NULL,
    [dt_create]  DATETIME2 (0) NULL,
    [dt_publish] DATETIME2 (0) NULL,
    CONSTRAINT [PK_ProductsForEAN2] PRIMARY KEY CLUSTERED ([pants_id] ASC),
    CONSTRAINT [FK_ProductsForEAN2_pants_id] FOREIGN KEY ([pants_id]) REFERENCES [Products].[ProdArticleNomenclatureTechSize] ([pants_id])
);


GO
CREATE NONCLUSTERED INDEX [IX_ProductsForEAN2_pants_id_dt_publish]
    ON [Synchro].[ProductsForEAN2]([pants_id] ASC) WHERE ([dt_publish] IS NULL)
    ON [Indexes];


GO
CREATE NONCLUSTERED INDEX [IX_ProductsForEAN2_pants_id]
    ON [Synchro].[ProductsForEAN2]([pants_id] ASC) WHERE ([dt_create] IS NULL)
    ON [Indexes];

