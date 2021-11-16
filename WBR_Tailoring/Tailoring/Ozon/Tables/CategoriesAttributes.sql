CREATE TABLE [Ozon].[CategoriesAttributes]
(
	category_id      INT CONSTRAINT [FK_CategoriesAttributes_category_id] FOREIGN KEY REFERENCES Ozon.Categories(category_id) NOT NULL,
	attribute_id     INT CONSTRAINT [FK_CategoriesAttributes_attribute_id] FOREIGN KEY REFERENCES Ozon.Attributes(attribute_id) NOT NULL,
	is_required      BIT NOT NULL,
	CONSTRAINT [PK_CategoriesAttributes] PRIMARY KEY CLUSTERED(category_id, attribute_id)
)
	