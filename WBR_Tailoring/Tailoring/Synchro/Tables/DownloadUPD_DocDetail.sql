CREATE TABLE [Synchro].[DownloadUPD_DocDetail]
(
	dudd_id                    INT IDENTITY(1, 1) CONSTRAINT [PK_DownloadUPD_DocDetail] PRIMARY KEY CLUSTERED NOT NULL,
	dud_id                     INT CONSTRAINT [FK_DownloadUPD_DocDetail_dud_id] FOREIGN KEY REFERENCES Synchro.DownloadUPD_Doc(dud_id) NOT NULL,
	esf_id                     INT NOT NULL,
	edo_pos_id                 INT NOT NULL,
	dui_id_item_name           INT CONSTRAINT [FK_DownloadUPD_DocDetail_dui_id_item_name] FOREIGN KEY REFERENCES Synchro.DownloadUPD_Item(dui_id) NULL,
	edo_okei_code              VARCHAR(4) NULL,
	okei_name                  VARCHAR(15) NULL,
	edo_quantity               DECIMAL(26, 11) NULL,
	edo_price                  DECIMAL(17, 2) NULL,
	dui_id_item_article        INT CONSTRAINT [FK_DownloadUPD_DocDetail_dui_id_dui_id_item_article] FOREIGN KEY REFERENCES Synchro.DownloadUPD_Item(dui_id) NULL,
	dui_id_item_code           INT CONSTRAINT [FK_DownloadUPD_DocDetail_dui_id_dui_id_item_code] FOREIGN KEY REFERENCES Synchro.DownloadUPD_Item(dui_id) NULL,
	dui_id_item_spec           INT CONSTRAINT [FK_DownloadUPD_DocDetail_dui_id_dui_id_item_spec] FOREIGN KEY REFERENCES Synchro.DownloadUPD_Item(dui_id) NULL,
	edo_amount_nds             DECIMAL(17, 2) NULL,
	edo_amount_with_nds        DECIMAL(19, 2) NULL,
	edo_amount_without_nds     DECIMAL(19, 2) NULL,
	edo_vat                    DECIMAL(10, 5) NULL,
	gtd_id                     INT CONSTRAINT [FK_DownloadUPD_DocDetail_gtd_id] FOREIGN KEY REFERENCES Material.GTD(gtd_id) NULL,
	edo_country_id             INT NULL
)

GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_DownloadUPD_DocDetail_dud_id_edo_pos_id] ON Synchro.DownloadUPD_DocDetail(dud_id, edo_pos_id) ON [Indexes]