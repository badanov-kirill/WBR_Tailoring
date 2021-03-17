CREATE TABLE [Ozon].[Articles]
(
	article_id         INT IDENTITY(1, 1) CONSTRAINT [PK_OzonArticles] PRIMARY KEY CLUSTERED NOT NULL,
	pants_id           INT CONSTRAINT [FK_OzonArticles_pants_id] FOREIGN KEY REFERENCES Products.ProdArticleNomenclatureTechSize(pants_id),
	art                VARCHAR(75) NOT NULL,
	ozon_id            INT NOT NULL,
	ozon_fbo_id        INT NOT NULL,
	ozon_fbs_id        INT NOT NULL,
	price_with_vat     DECIMAL(9, 2) NOT NULL
)

GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_OzonArticles_pants_id] ON Ozon.Articles(pants_id) ON [Indexes]