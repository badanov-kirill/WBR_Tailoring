CREATE TABLE [Ozon].[CategoriesAttributeValues]
(
	category_id      BIGINT CONSTRAINT [FK_CategoriesAttributeValues_category_id] FOREIGN KEY REFERENCES Ozon.Categories(category_id) NOT NULL,
	attribute_id     BIGINT CONSTRAINT [FK_CategoriesAttributeValues_attribute_id] FOREIGN KEY REFERENCES Ozon.Attributes(attribute_id) NOT NULL,
	av_id            BIGINT NOT NULL,
	CONSTRAINT [PK_CategoriesAttributeValues] PRIMARY KEY CLUSTERED(category_id, attribute_id, av_id)
)
