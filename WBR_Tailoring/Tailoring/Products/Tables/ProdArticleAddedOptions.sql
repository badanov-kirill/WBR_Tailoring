CREATE TABLE [Products].[ProdArticleAddedOption]
(
	pa_id           INT CONSTRAINT [FK_ProdArticleAddedOption_pa_id] FOREIGN KEY REFERENCES Products.ProdArticle(pa_id) NOT NULL,
	ao_id           INT CONSTRAINT [FK_ProdArticleAddedOption_ao_id] FOREIGN KEY REFERENCES Products.AddedOption(ao_id) NOT NULL,
	employee_id     INT NOT NULL,
	dt              dbo.SECONDSTIME NOT NULL,
	ao_value        DECIMAL(9, 2) NULL,
	si_id           INT CONSTRAINT [FK_ProdArticleAddedOption_si_id] FOREIGN KEY REFERENCES Products.SI (si_id) NULL,
	CONSTRAINT [PK_ProdArticleAddedOption] PRIMARY KEY CLUSTERED(pa_id, ao_id)
);

GO
