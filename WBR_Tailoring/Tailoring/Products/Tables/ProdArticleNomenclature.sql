CREATE TABLE [Products].[ProdArticleNomenclature] (
    [pan_id]                    INT                 IDENTITY (1, 1) NOT NULL,
    [pa_id]                     INT                 NOT NULL,
    [sa]                        VARCHAR (36)        NOT NULL,
    [is_deleted]                BIT                 NOT NULL,
    [employee_id]               INT                 NOT NULL,
    [dt]                        [dbo].[SECONDSTIME] NOT NULL,
    [nm_id]                     INT                 NULL,
    [whprice]                   DECIMAL (9, 2)      NULL,
    [price_ru]                  DECIMAL (9, 2)      NULL,
    [cutting_degree_difficulty] DECIMAL (4, 2)      NULL,
    [pics_dt]                   DATE                NULL,
    CONSTRAINT [PK_ProdArticleNomenclature] PRIMARY KEY CLUSTERED ([pan_id] ASC),
    CONSTRAINT [FK_ProdArticleNomenclature_pa_id] FOREIGN KEY ([pa_id]) REFERENCES [Products].[ProdArticle] ([pa_id])
);





GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_ProdArticleNomenclature_pa_id_sa] ON Products.ProdArticleNomenclature(pa_id, sa) ON [Indexes]; 

GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_ProdArticleNomenclature_nm_id] ON Products.ProdArticleNomenclature(nm_id) WHERE nm_id IS NOT NULL ON [Indexes]; 
GO


