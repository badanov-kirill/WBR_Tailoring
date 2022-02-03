CREATE TABLE [Ozon].[ArticleSaveTaskProdArticleTS]
(
	task_id BIGINT NOT NULL,	
	pants_id INT CONSTRAINT [FK_ArticleSaveTaskProdArticleTS_pants_id] FOREIGN KEY REFERENCES Products.ProdArticleNomenclatureTechSize(pants_id) NOT NULL,	
	dt DATETIME2(0) NOT NULL,
	CONSTRAINT [PK_ArticleSaveTaskProdArticleTS] PRIMARY KEY CLUSTERED (task_id, pants_id)
)
