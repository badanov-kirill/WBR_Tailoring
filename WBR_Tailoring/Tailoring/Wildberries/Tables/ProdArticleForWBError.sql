CREATE TABLE [Wildberries].[ProdArticleForWBError] (
    [pa_id]         INT           NOT NULL,
    [dt]            DATETIME      NOT NULL,
    [error_text]    VARCHAR (MAX) NOT NULL,
    [send_message]  VARCHAR (MAX) NULL,
    [send_type]     VARCHAR (10)  NOT NULL,
    [error_code]    VARCHAR (5)   NULL,
    [fabricator_id] INT           NOT NULL,
    CONSTRAINT [PK_ProdArticleForWBError] PRIMARY KEY CLUSTERED ([pa_id] ASC, [fabricator_id] ASC, [dt] ASC),
    CONSTRAINT [FK_ProdArticleForWBError_pa_id] FOREIGN KEY ([pa_id]) REFERENCES [Products].[ProdArticle] ([pa_id])
);


