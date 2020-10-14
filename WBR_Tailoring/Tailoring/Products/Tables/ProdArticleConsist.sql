CREATE TABLE [Products].[ProdArticleConsist]
(
	pa_id           INT CONSTRAINT [FK_ProdArticleConsist_pa_id] FOREIGN KEY REFERENCES Products.ProdArticle(pa_id) NOT NULL,
	consist_id      INT CONSTRAINT [FK_ProdArticleConsist_consist_id] FOREIGN KEY REFERENCES Products.Consist(consist_id) NOT NULL,
	percnt          TINYINT CONSTRAINT [CH_ProdArticleConsist_percnt] CHECK(percnt >= (0) AND percnt <= (100)) NOT NULL,
	employee_id     INT NOT NULL,
	dt              dbo.SECONDSTIME NOT NULL,
	CONSTRAINT [PK_ProdArticleConsist] PRIMARY KEY CLUSTERED(pa_id, consist_id)
);