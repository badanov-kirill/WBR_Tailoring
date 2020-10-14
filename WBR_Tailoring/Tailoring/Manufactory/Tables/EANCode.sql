CREATE TABLE [Manufactory].[EANCode]
(
	pants_id     INT CONSTRAINT [FK_EANCode_pants_id] FOREIGN KEY REFERENCES Products.ProdArticleNomenclatureTechSize(pants_id) NOT NULL,
	ean          VARCHAR(13) NOT NULL,
	CONSTRAINT [PK_EANCode] PRIMARY KEY CLUSTERED(pants_id)
)

GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_EANCode] ON Manufactory.EANCode(ean) ON [Indexes]