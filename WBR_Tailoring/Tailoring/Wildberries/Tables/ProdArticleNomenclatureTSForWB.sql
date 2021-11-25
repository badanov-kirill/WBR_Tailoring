CREATE TABLE [Wildberries].[ProdArticleNomenclatureTSForWB]
(
	pants_id INT CONSTRAINT [PK_ProdArticleNomenclatureTSForWB] PRIMARY KEY CLUSTERED NOT NULL,
	wb_uid BINARY(16) NULL,
	chrt_id INT NOT NULL,
	dt DATETIME2(0) NOT NULL
)
