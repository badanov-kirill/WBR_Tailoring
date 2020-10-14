CREATE TABLE [History].[ProdArticleNomenclaturePrice]
(
	pap_id INT IDENTITY(1,1) CONSTRAINT [PK_ProdArticleNomenclaturePrice] PRIMARY KEY CLUSTERED NOT NULL,
	pan_id INT NULL,
	whprice DECIMAL(9,2) NULL,
	price_ru DECIMAL(9,2) NULL,
	employee_id INT NULL,
	dt dbo.SECONDSTIME NULL
)
