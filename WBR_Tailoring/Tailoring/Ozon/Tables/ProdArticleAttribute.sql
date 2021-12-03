CREATE TABLE [Ozon].[ProdArticleAttribute]
(
	pa_id               INT CONSTRAINT [FK_ProdArticleAttribute_pa_id] FOREIGN KEY REFERENCES Products.ProdArticle(pa_id) NOT NULL,
	attribute_id        BIGINT CONSTRAINT [FK_ProdArticleAttribute_attribute_id] FOREIGN KEY REFERENCES Ozon.Attributes(attribute_id) NOT NULL,
	attribute_value     VARCHAR(50) NOT NULL,
	employee_id         INT NOT NULL,
	dt                  DATETIME2(0) NOT NULL,
	CONSTRAINT [PK_ProdArticleAttribute] PRIMARY KEY CLUSTERED(pa_id, attribute_id)
)
