CREATE TABLE [Products].[ProdArticleNomenclatureNeedPrice]
(
	pan_id INT CONSTRAINT [FK_ProdArticleNomenclatureNeedPrice_pan_id] FOREIGN KEY REFERENCES Products.ProdArticleNomenclature(pan_id) NOT NULL,
	dt dbo.SECONDSTIME NOT NULL,
	employee_id INT NOT NULL,
	CONSTRAINT [PK_ProdArticleNomenclatureNeedPrice] PRIMARY KEY CLUSTERED (pan_id)
)