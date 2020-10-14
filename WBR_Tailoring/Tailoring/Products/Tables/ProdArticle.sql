CREATE TABLE [Products].[ProdArticle] (
    [pa_id]                 INT                 IDENTITY (1, 1) NOT NULL,
    [sketch_id]             INT                 NOT NULL,
    [is_deleted]            BIT                 NOT NULL,
    [model_number]          INT                 NOT NULL,
    [descr]                 VARCHAR (1000)      NULL,
    [brand_id]              INT                 NOT NULL,
    [season_id]             INT                 NULL,
    [collection_id]         INT                 NULL,
    [style_id]              INT                 NULL,
    [direction_id]          INT                 NULL,
    [create_employee_id]    INT                 NOT NULL,
    [create_dt]             [dbo].[SECONDSTIME] NOT NULL,
    [employee_id]           INT                 NOT NULL,
    [dt]                    [dbo].[SECONDSTIME] NOT NULL,
    [rv]                    ROWVERSION          NOT NULL,
    [ao_ts_id]              INT                 NULL,
    [imt_id]                INT                 NULL,
    [is_not_new]            BIT                 CONSTRAINT [DF_ProdArticle_is_not_new] DEFAULT ((0)) NOT NULL,
    [sa]                    VARCHAR (36)        NOT NULL,
    [cut_comment]           VARCHAR (200)       NULL,
    [sew_comment]           VARCHAR (200)       NULL,
    [from_site_dt]          DATETIME2 (0)       NULL,
    [from_site_employee_id] INT                 NULL,
    CONSTRAINT [PK_ProdArticle] PRIMARY KEY CLUSTERED ([pa_id] ASC),
    CONSTRAINT [FK_ProdArticle_ao_ts_id] FOREIGN KEY ([ao_ts_id]) REFERENCES [Products].[TechSize] ([ts_id]),
    CONSTRAINT [FK_ProdArticle_brand_id] FOREIGN KEY ([brand_id]) REFERENCES [Products].[Brand] ([brand_id]),
    CONSTRAINT [FK_ProdArticle_collection_id] FOREIGN KEY ([collection_id]) REFERENCES [Products].[Collection] ([collection_id]),
    CONSTRAINT [FK_ProdArticle_direction_id] FOREIGN KEY ([direction_id]) REFERENCES [Products].[Direction] ([direction_id]),
    CONSTRAINT [FK_ProdArticle_season_id] FOREIGN KEY ([season_id]) REFERENCES [Products].[Season] ([season_id]),
    CONSTRAINT [FK_ProdArticle_sketch_id] FOREIGN KEY ([sketch_id]) REFERENCES [Products].[Sketch] ([sketch_id]),
    CONSTRAINT [FK_ProdArticle_style_id] FOREIGN KEY ([style_id]) REFERENCES [Products].[Style] ([style_id])
);



GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_ProdArticle_imt_id] ON Products.ProdArticle(imt_id) WHERE imt_id IS NOT NULL ON [Indexes]

GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_ProdArticle_sa] ON Products.ProdArticle(sa) ON [Indexes]

GO
CREATE NONCLUSTERED INDEX [IX_ProdArticle_sketch_id_is_deleted] ON Products.ProdArticle(sketch_id,is_deleted) ON [Indexes]
GO
GRANT SELECT
    ON OBJECT::[Products].[ProdArticle] TO [wildberries\olap-orr]
    AS [dbo];

