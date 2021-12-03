CREATE TABLE [Ozon].[ProdArticleAttributeValues]
(
	pa_id            INT CONSTRAINT [FK_ProdArticleAttributeValues_pa_id] FOREIGN KEY REFERENCES Products.ProdArticle(pa_id) NOT NULL,
	attribute_id     BIGINT CONSTRAINT [FK_ProdArticleAttributeValues_attribute_id] FOREIGN KEY REFERENCES Ozon.Attributes(attribute_id) NOT NULL,
	av_id            BIGINT CONSTRAINT [FK_ProdArticleAttributeValues_av_id] FOREIGN KEY REFERENCES Ozon.AttributeValues(av_id) NOT NULL,
	employee_id      INT NOT NULL,
	dt               DATETIME2(0) NOT NULL,
	CONSTRAINT [PK_ProdArticleAttributeValues] PRIMARY KEY CLUSTERED(pa_id, attribute_id, av_id)
)
