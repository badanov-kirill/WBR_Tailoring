CREATE TABLE [Material].[RawMaterialInvoiceCorrectionInvoiceDetail]
(
	rmicid_id                   INT IDENTITY(1, 1) CONSTRAINT [PK_RawMaterialInvoiceCorrectionInvoiceDetail] PRIMARY KEY CLUSTERED NOT NULL,
	rmic_id                     INT CONSTRAINT [FK_RawMaterialInvoiceCorrectionInvoiceDetail_rmic_id] FOREIGN KEY REFERENCES Material.RawMaterialInvoiceCorrection(rmic_id) NOT NULL,
	rmid_id                     INT CONSTRAINT [FK_RawMaterialInvoiceCorrectionInvoiceDetail_rmid_id] FOREIGN KEY REFERENCES Material.RawMaterialInvoiceDetail(rmid_id) NOT NULL,
	rmii_id                     INT CONSTRAINT [FK_RawMaterialInvoiceCorrectionInvoiceDetail_rmii_id] FOREIGN KEY REFERENCES Material.RawMaterialInvoiceItem(rmii_id) NOT NULL,
	price                       DECIMAL(9, 2) NOT NULL,
	base_quantity               DECIMAL(9, 3) NOT NULL,
	base_amount_with_nds        DECIMAL(9, 2) NOT NULL,
	base_amount_nds             DECIMAL(9, 2) NOT NULL,
	base_amount_without_nds     DECIMAL(9, 2) NOT NULL,
	nds                         TINYINT CONSTRAINT [FK_RawMaterialInvoiceCorrectionInvoiceDetail_nds] FOREIGN KEY REFERENCES RefBook.NDS(nds) NOT NULL,
	okei_id                     INT CONSTRAINT [FK_RawMaterialInvoiceCorrectionInvoiceDetail_okei_id] FOREIGN KEY REFERENCES Qualifiers.OKEI(okei_id) NOT NULL,
	country_id                  INT CONSTRAINT [FK_RawMaterialInvoiceCorrectionInvoiceDetail_country_id] FOREIGN KEY REFERENCES RefBook.Countries(country_id) NOT NULL,
	gtd_id                      INT CONSTRAINT [FK_RawMaterialInvoiceCorrectionInvoiceDetail_gtd_id] FOREIGN KEY REFERENCES Material.GTD(gtd_id) NULL,
	base_item_number            SMALLINT NOT NULL,
	return_quantity             DECIMAL(9, 3) NOT NULL,
	item_number                 SMALLINT NOT NULL,
	rmt_id                      INT CONSTRAINT [FK_RawMaterialInvoiceCorrectionInvoiceDetail_rmt_id] FOREIGN KEY REFERENCES Material.RawMaterialType(rmt_id)  NOT NULL
)
