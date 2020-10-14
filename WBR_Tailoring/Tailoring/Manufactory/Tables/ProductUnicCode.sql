CREATE TABLE [Manufactory].[ProductUnicCode] (
    [product_unic_code] INT                 NOT NULL,
    [pants_id]          INT                 NOT NULL,
    [operation_id]      SMALLINT            NOT NULL,
    [dt]                [dbo].[SECONDSTIME] CONSTRAINT [DF_ProductUnicCode_dt] DEFAULT (getdate()) NOT NULL,
    [pt_id]             TINYINT             NOT NULL,
    [cutting_id]        INT                 NULL,
    [packing_dt] DATETIME2(0) NULL
    CONSTRAINT [PK_ProductUnicCode] PRIMARY KEY CLUSTERED ([product_unic_code] ASC),
    CONSTRAINT [FK_ProductUnicCode_cutting_id] FOREIGN KEY ([cutting_id]) REFERENCES [Manufactory].[Cutting] ([cutting_id]),
    CONSTRAINT [FK_ProductUnicCode_operation_id] FOREIGN KEY ([operation_id]) REFERENCES [Manufactory].[Operation] ([operation_id]),
    CONSTRAINT [FK_ProductUnicCode_pants_id] FOREIGN KEY ([pants_id]) REFERENCES [Products].[ProdArticleNomenclatureTechSize] ([pants_id]),
    CONSTRAINT [FK_ProductUnicCode_pt_id] FOREIGN KEY ([pt_id]) REFERENCES [Products].[ProductType] ([pt_id])
);



GO
CREATE NONCLUSTERED INDEX [IX_ProductUnicCode_pants_id] ON Manufactory.ProductUnicCode(pants_id) INCLUDE(product_unic_code) ON [Indexes]
GO
CREATE NONCLUSTERED INDEX [IX_ProductUnicCode_operation_id] ON Manufactory.ProductUnicCode (operation_id, dt) INCLUDE(pants_id, cutting_id) ON [Indexes]
GO
CREATE NONCLUSTERED INDEX [IX_ProductUnicCode_cutting_id_operation_id] ON Manufactory.ProductUnicCode (cutting_id, operation_id) ON [Indexes]
GO
CREATE NONCLUSTERED INDEX [IX_ProductUnicCode_packing_dt] ON Manufactory.ProductUnicCode (packing_dt) INCLUDE(operation_id, pants_id, cutting_id) WHERE packing_dt IS NOT NULL ON [Indexes]
GO
GRANT SELECT
    ON OBJECT::[Manufactory].[ProductUnicCode] TO [wildberries\olap-orr]
    AS [dbo];

