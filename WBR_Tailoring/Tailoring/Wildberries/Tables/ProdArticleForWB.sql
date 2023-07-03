CREATE TABLE [Wildberries].[ProdArticleForWB] (
    [pa_id]         INT           NOT NULL,
    [dt]            DATETIME2 (0) NOT NULL,
    [send_dt]       DATETIME2 (0) NULL,
    [imt_uid]       BINARY (16)   NULL,
    [is_error]      BIT           NULL,
    [load_nm_dt]    DATETIME2 (0) NULL,
    [imt_id]        INT           NULL,
    [fabricator_id] INT           NOT NULL,
    CONSTRAINT [PK_ProdArticleForWB] PRIMARY KEY CLUSTERED ([pa_id] ASC, [fabricator_id] ASC),
    CONSTRAINT [FK_ProdArticleForWB_pa_id] FOREIGN KEY ([pa_id]) REFERENCES [Products].[ProdArticle] ([pa_id])
);


