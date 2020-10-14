CREATE TABLE [Material].[Article] (
    [art_id]   INT          IDENTITY (1, 1) NOT NULL,
    [art_name] VARCHAR (12) NULL,
    CONSTRAINT [PK_Article] PRIMARY KEY CLUSTERED ([art_id] ASC)
);



GO

CREATE UNIQUE NONCLUSTERED INDEX [UQ_Article_art_name] ON Material.Article(art_name) ON [Indexes] 

GO
GRANT SELECT
    ON OBJECT::[Material].[Article] TO [wildberries\olap-orr]
    AS [dbo];

