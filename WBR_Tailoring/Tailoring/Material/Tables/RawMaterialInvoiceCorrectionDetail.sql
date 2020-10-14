CREATE TABLE [Material].[RawMaterialInvoiceCorrectionDetail]
(
	rmicd_id                       INT IDENTITY(1, 1) CONSTRAINT [PK_RawMaterialInvoiceCorrectionDetail] PRIMARY KEY CLUSTERED NOT NULL,
	rmic_id                        INT CONSTRAINT [FK_RawMaterialInvoiceCorrectionDetail_rmic_id] FOREIGN KEY REFERENCES Material.RawMaterialInvoiceCorrection(rmic_id) NOT NULL,
	return_dt                      DATETIME2(0) NULL,
	return_employee_id             INT NULL,
	rmid_id                        INT NOT NULL,
	shkrm_id                       INT CONSTRAINT [FK_RawMaterialInvoiceCorrectionDetail_shkrm_id] FOREIGN KEY REFERENCES Warehouse.SHKRawMaterial(shkrm_id) NOT NULL,
	rmt_id                         INT CONSTRAINT [FK_RawMaterialInvoiceCorrectionDetail_rmt_id] FOREIGN KEY REFERENCES Material.RawMaterialType(rmt_id) NOT NULL,
	art_id                         INT CONSTRAINT [FK_RawMaterialInvoiceCorrectionDetail_art_id] FOREIGN KEY REFERENCES Material.Article(art_id) NOT NULL,
	color_id                       INT CONSTRAINT [FK_RawMaterialInvoiceCorrectionDetail_color_id] FOREIGN KEY REFERENCES Material.ClothColor(color_id) NOT NULL,
	suppliercontract_id            INT CONSTRAINT [FK_RawMaterialInvoiceCorrectionDetail_suppliercontract_id] FOREIGN KEY REFERENCES Suppliers.SupplierContract(suppliercontract_id) 
	NOT NULL,
	su_id                          INT CONSTRAINT [FK_RawMaterialInvoiceCorrectionDetail_su_id] FOREIGN KEY REFERENCES RefBook.SpaceUnit(su_id) NOT NULL,
	okei_id                        INT CONSTRAINT [FK_RawMaterialInvoiceCorrectionDetail_okei_id] FOREIGN KEY REFERENCES Qualifiers.OKEI(okei_id) NOT NULL,
	qty                            DECIMAL(9, 2) NOT NULL,
	stor_unit_residues_okei_id     INT CONSTRAINT [FK_RawMaterialInvoiceCorrectionDetail_stor_unit_residues_okei_id] FOREIGN KEY REFERENCES Qualifiers.OKEI(okei_id) 
	NOT NULL,
	stor_unit_residues_qty         DECIMAL(9, 2) NOT NULL,
	shksu_id                       INT CONSTRAINT [FK_RawMaterialInvoiceCorrectionDetail_shksu_id] FOREIGN KEY REFERENCES Warehouse.SHKSpaceUnit(shksu_id) NOT NULL,
	frame_width                    SMALLINT NULL,
	is_defected                    BIT NOT NULL,
	nds                            TINYINT NOT NULL,
	dt                             DATETIME2(0) NOT NULL,
	employee_id                    INT NOT NULL,
	amount                         DECIMAL(19, 8) NOT NULL
)
