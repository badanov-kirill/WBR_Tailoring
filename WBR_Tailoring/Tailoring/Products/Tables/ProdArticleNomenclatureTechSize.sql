CREATE TABLE [Products].[ProdArticleNomenclatureTechSize] (
    [pants_id]    INT                 IDENTITY (1, 1) NOT NULL,
    [pan_id]      INT                 NOT NULL,
    [ts_id]       INT                 NOT NULL,
    [is_deleted]  BIT                 NOT NULL,
    [employee_id] INT                 NOT NULL,
    [dt]          [dbo].[SECONDSTIME] NOT NULL,
    CONSTRAINT [PK_ProdArticleNomenclatureTechSize] PRIMARY KEY CLUSTERED ([pants_id] ASC),
    CONSTRAINT [FK_ProdArticleNomenclatureTechSize_pan_id] FOREIGN KEY ([pan_id]) REFERENCES [Products].[ProdArticleNomenclature] ([pan_id]),
    CONSTRAINT [FK_ProdArticleNomenclatureTechSize_ts_id] FOREIGN KEY ([ts_id]) REFERENCES [Products].[TechSize] ([ts_id])
);



GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_ProdArticleNomenclatureTechSize_pan_id_ts_id] ON Products.ProdArticleNomenclatureTechSize(pan_id, ts_id) ON [Indexes]
GO
GRANT SELECT
    ON OBJECT::[Products].[ProdArticleNomenclatureTechSize] TO [wildberries\olap-orr]
    AS [dbo];

