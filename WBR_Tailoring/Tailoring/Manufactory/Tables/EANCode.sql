CREATE TABLE [Manufactory].[EANCode] (
    [pants_id]      INT          NOT NULL,
    [ean]           VARCHAR (13) NOT NULL,
    [fabricator_id] INT          NOT NULL,
    CONSTRAINT [PK_EANCode] PRIMARY KEY CLUSTERED ([pants_id] ASC, [fabricator_id] ASC),
    CONSTRAINT [FK_EANCode_fabricator_id] FOREIGN KEY ([fabricator_id]) REFERENCES [Settings].[Fabricators] ([fabricator_id]),
    CONSTRAINT [FK_EANCode_pants_id] FOREIGN KEY ([pants_id]) REFERENCES [Products].[ProdArticleNomenclatureTechSize] ([pants_id])
);



GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_EANCode] ON Manufactory.EANCode(ean) ON [Indexes]