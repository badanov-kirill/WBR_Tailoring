CREATE TABLE [Material].[GTD]
(
	gtd_id      INT IDENTITY(1, 1) NOT NULL,
	gtd_cod     VARCHAR(30) NOT NULL,
	CONSTRAINT [PK_GTD] PRIMARY KEY CLUSTERED(gtd_id ASC)
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [UX_GTD_gtd_cod]
    ON Material.GTD(gtd_cod ASC)
    ON [Indexes];