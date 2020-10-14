CREATE TABLE [Synchro].[DownloadUPD_DocType]
(
	dudt_id      SMALLINT IDENTITY(1, 1) CONSTRAINT [PK_DownloadUPD_DocType] PRIMARY KEY CLUSTERED NOT NULL,
	upd_type     VARCHAR(10) NOT NULL
)

GO

CREATE UNIQUE NONCLUSTERED INDEX [UQ_DownloadUPD_DocType_upd_type] ON Synchro.DownloadUPD_DocType(upd_type) ON [Indexes]
