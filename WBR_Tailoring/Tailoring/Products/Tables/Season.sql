CREATE TABLE [Products].[Season]
(
	season_id       INT IDENTITY(1, 1) CONSTRAINT [PK_Season] PRIMARY KEY CLUSTERED NOT NULL,
	season_name     VARCHAR(30) NOT NULL,
	employee_id     INT NOT NULL,
	dt              [dbo].[SECONDSTIME] NOT NULL,
	isdeleted       BIT NOT NULL,
	erp_id          INT NOT NULL
)

GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_Season_season_name] ON Products.Season(season_name) WHERE isdeleted = 0 ON [Indexes]
GO