CREATE TABLE [Products].[ProdArticleNomenclatureColor]
(
	pan_id          INT CONSTRAINT [FK_ProdArticleNomenclatureColor_pan_id] FOREIGN KEY REFERENCES Products.ProdArticleNomenclature(pan_id) NOT NULL,
	color_cod       INT CONSTRAINT [FK_ProdArticleNomenclatureColor_color_cod] FOREIGN KEY REFERENCES Products.Color (color_cod) NOT NULL,
	is_main         BIT NOT NULL,
	employee_id     INT NOT NULL,
	dt              dbo.SECONDSTIME NOT NULL,
	CONSTRAINT [PK_ProdArticleNomenclatureColor] PRIMARY KEY CLUSTERED(pan_id, color_cod)
)

GO

CREATE UNIQUE NONCLUSTERED INDEX [UQ_ProdArticleNomenclatureColor_pan_id_is_mail] ON Products.ProdArticleNomenclatureColor(pan_id, is_main) WHERE (is_main = 1) 
ON [Indexes]; 