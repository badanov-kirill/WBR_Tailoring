CREATE TABLE [Synchro].[DownloadUPD_Mapping]
(
	esf_id     INT CONSTRAINT [PK_DownloadUPD_Mapping] PRIMARY KEY CLUSTERED NOT NULL,
	rmi_id     INT CONSTRAINT [FK_DownloadUPD_Mapping_rmi_id] FOREIGN KEY REFERENCES Material.RawMaterialInvoice(rmi_id) NOT NULL,
	dud_id     INT CONSTRAINT [FK_DownloadUPD_Mapping_dud_id] FOREIGN KEY REFERENCES Synchro.DownloadUPD_Doc(dud_id) NOT NULL
)
GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_DownloadUPD_Mapping_rmi_id] ON Synchro.DownloadUPD_Mapping(rmi_id) ON [Indexes]