CREATE TABLE [Wildberries].[ProdArticleNomenclatureForWB] (
    [pan_id]        INT           NOT NULL,
    [pa_id]         INT           NOT NULL,
    [dt]            DATETIME2 (0) NOT NULL,
    [nm_id]         INT           NULL,
    [wb_uid]        BINARY (16)   NULL,
    [fabricator_id] INT           NOT NULL,
    CONSTRAINT [PK_ProdArticleNomenclatureForWB] PRIMARY KEY CLUSTERED ([pan_id] ASC),
    CONSTRAINT [FK_ProdArticleNomenclatureForWB_pa_id] FOREIGN KEY ([pa_id]) REFERENCES [Products].[ProdArticle] ([pa_id]),
    CONSTRAINT [FK_ProdArticleNomenclatureForWB_pan_id] FOREIGN KEY ([pan_id]) REFERENCES [Products].[ProdArticleNomenclature] ([pan_id])
);


