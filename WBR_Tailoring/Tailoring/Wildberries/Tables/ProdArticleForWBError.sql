CREATE TABLE [Wildberries].[ProdArticleForWBError]
(
	pa_id          INT CONSTRAINT [FK_ProdArticleForWBError_pa_id] FOREIGN KEY REFERENCES Products.ProdArticle(pa_id) NOT NULL,
	dt             DATETIME2(0) NOT NULL,
	error_text     VARCHAR(900) NOT NULL,
	CONSTRAINT [PK_ProdArticleForWBError] PRIMARY KEY CLUSTERED(pa_id)
)
