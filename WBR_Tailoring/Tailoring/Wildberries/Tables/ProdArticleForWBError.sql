CREATE TABLE [Wildberries].[ProdArticleForWBError]
(
	pa_id            INT CONSTRAINT [FK_ProdArticleForWBError_pa_id] FOREIGN KEY REFERENCES Products.ProdArticle(pa_id) NOT NULL,
	dt               DATETIME NOT NULL,
	error_text       VARCHAR(MAX) NOT NULL,
	send_message     VARCHAR(MAX) NULL,
	send_type        VARCHAR(10) NOT NULL,
	error_code		 VARCHAR(5) NULL,
	CONSTRAINT [PK_ProdArticleForWBError] PRIMARY KEY CLUSTERED(pa_id, dt)
)
