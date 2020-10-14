CREATE TABLE [Synchro].[DownloadUPD_Item]
(
	dui_id        INT NOT NULL IDENTITY(1, 1) CONSTRAINT [PK_DownloadUPD_Item] PRIMARY KEY CLUSTERED,
	item_name     VARCHAR(200) NOT NULL
)
GO

CREATE UNIQUE NONCLUSTERED INDEX [UQ_DownloadUPD_Item] ON Synchro.DownloadUPD_Item(item_name)
ON [Indexes]
GO