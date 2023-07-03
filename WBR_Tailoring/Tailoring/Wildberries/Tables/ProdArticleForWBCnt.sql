CREATE TABLE [Wildberries].[ProdArticleForWBCnt] (
    [pa_id]         INT           NOT NULL,
    [cnt_save]      INT           NOT NULL,
    [cnt_load]      INT           NOT NULL,
    [dt]            DATETIME2 (0) NOT NULL,
    [dt_save]       DATETIME2 (0) NOT NULL,
    [dt_load]       DATETIME2 (0) NOT NULL,
    [fabricator_id] INT           NOT NULL,
    CONSTRAINT [PK_ProdArticleForWBCnt] PRIMARY KEY CLUSTERED ([pa_id] ASC, [fabricator_id] ASC),
    CONSTRAINT [FK_ProdArticleForWBCnt_pa_id] FOREIGN KEY ([pa_id]) REFERENCES [Products].[ProdArticle] ([pa_id])
);


