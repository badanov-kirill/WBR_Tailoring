CREATE TABLE [Material].[RawMaterialInvoiceDetail]
(
	rmid_id                INT NOT NULL IDENTITY(1, 1) CONSTRAINT [PK_RawMaterialInvoiceDetail] PRIMARY KEY CLUSTERED,
	rmi_id                 INT NOT NULL CONSTRAINT [FK_RawMaterialInvoiceDetail_rmi_id] FOREIGN KEY REFERENCES Material.RawMaterialInvoice(rmi_id),
	rmii_id                INT NOT NULL CONSTRAINT [FK_RawMaterialInvoiceDetail_rmii_id] FOREIGN KEY REFERENCES Material.RawMaterialInvoiceItem(rmii_id),
	price                  DECIMAL(9, 2) NOT NULL,
	quantity               DECIMAL(9, 3) NOT NULL,
	amount_with_nds        DECIMAL(9, 2) NOT NULL,
	amount_nds             DECIMAL(9, 2) NOT NULL,
	amount_without_nds     DECIMAL(9, 2) NOT NULL,
	nds                    TINYINT NOT NULL CONSTRAINT [FK_RawMaterialInvoiceDetail_nds] FOREIGN KEY REFERENCES RefBook.NDS(nds),
	okei_id                INT NOT NULL CONSTRAINT [FK_RawMaterialInvoiceDetail_okei_id] FOREIGN KEY REFERENCES Qualifiers.OKEI(okei_id),
	country_id             INT NOT NULL CONSTRAINT [FK_RawMaterialInvoiceDetail_country_id] FOREIGN KEY REFERENCES RefBook.Countries(country_id),
	gtd_id                 INT NULL CONSTRAINT [FK_RawMaterialInvoiceDetail_gtd_id] FOREIGN KEY REFERENCES Material.GTD(gtd_id),
	item_number            SMALLINT NOT NULL,
	rmiic_id			   INT NULL CONSTRAINT [FK_RawMaterialInvoiceDetail_rmiic_id] FOREIGN KEY REFERENCES Material.RawMaterialInvoiceItemCode(rmiic_id),
	amount_cur_with_nds    DECIMAL(9, 2) NULL,
)
GO

CREATE NONCLUSTERED INDEX [IX_RawMaterialInvoiceDetail_rm_inv_id] ON Material.RawMaterialInvoiceDetail(rmi_id) INCLUDE(quantity) ON [Indexes]
GO

CREATE UNIQUE NONCLUSTERED INDEX [UQ_RawMaterialInvoiceDetail_rmi_id_item_number] ON Material.RawMaterialInvoiceDetail (rmi_id, item_number) ON [Indexes]
GO