CREATE TABLE [Products].[ArtName] (
    [art_name_id] INT                 IDENTITY (1, 1) NOT NULL,
    [art_name]    VARCHAR (100)       NOT NULL,
    [employee_id] INT                 NOT NULL,
    [dt]          [dbo].[SECONDSTIME] NOT NULL,
    CONSTRAINT [PK_ArtName] PRIMARY KEY CLUSTERED ([art_name_id] ASC)
);




GO

CREATE UNIQUE NONCLUSTERED INDEX [UQ_ArtName_art_name] ON Products.ArtName(art_name) ON [Indexes]
GO


