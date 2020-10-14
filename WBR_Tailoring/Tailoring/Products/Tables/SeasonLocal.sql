CREATE TABLE [Products].[SeasonLocal]
(
	season_local_id       INT IDENTITY(1, 1) CONSTRAINT [PK_SeasonLocal] PRIMARY KEY CLUSTERED NOT NULL,
	season_local_name     VARCHAR(30) NOT NULL,
	employee_id           INT NOT NULL,
	dt                    DATETIME2(0) NOT NULL,
	is_deleted            BIT NOT NULL
)

GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_SeasonLocal_season_name] ON Products.SeasonLocal(season_local_name) WHERE is_deleted = 0 ON [Indexes]
GO