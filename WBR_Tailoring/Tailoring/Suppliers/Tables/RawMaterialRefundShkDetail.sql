CREATE TABLE [Suppliers].[RawMaterialRefundShkDetail]
(
	rmrsd_id                       INT NOT NULL IDENTITY(1, 1) CONSTRAINT [PK_RawMaterialRefundShkDetail] PRIMARY KEY CLUSTERED,
	rmr_id                         INT NOT NULL CONSTRAINT [FK_RawMaterialRefundShkDetail_rmr_id] FOREIGN KEY REFERENCES Suppliers.RawMaterialRefund(rmr_id),
	rmid_id                        INT NULL		CONSTRAINT [FK_RawMaterialRefundShkDetail_rmid] FOREIGN KEY REFERENCES Material.RawMaterialIncomeDetail(rmid_id),
	shkrm_id                       INT NOT NULL CONSTRAINT [FK_RawMaterialRefundShkDetail_shkrm_id] FOREIGN KEY REFERENCES Warehouse.SHKRawMaterial(shkrm_id) ,
	rmt_id                         INT NOT NULL CONSTRAINT [FK_RawMaterialRefundShkDetail_rmt_id] FOREIGN KEY REFERENCES Material.RawMaterialType(rmt_id) ,
	art_id                         INT NOT NULL CONSTRAINT [FK_RawMaterialRefundShkDetail_art_id] FOREIGN KEY REFERENCES Material.Article(art_id) ,
	color_id                       INT NOT NULL CONSTRAINT [FK_RawMaterialRefundShkDetail_color_id] FOREIGN KEY REFERENCES Material.ClothColor(color_id) ,
	qty                            DECIMAL(9, 3) NOT NULL,
	okei_id                        INT NOT NULL CONSTRAINT [FK_RawMaterialRefundShkDetail_okei_id] FOREIGN KEY REFERENCES Qualifiers.OKEI(okei_id),
	stor_unit_residues_okei_id     INT NOT NULL CONSTRAINT [FK_RawMaterialRefundShkDetail_stor_unit_residues_okei_id] FOREIGN KEY REFERENCES Qualifiers.OKEI(okei_id) ,
	stor_unit_residues_qty         DECIMAL(9, 3) NOT NULL,
	frame_width                    SMALLINT NULL,
	is_deleted                     BIT NOT NULL,
	dt                             DATETIME2(0) NOT NULL,
	employee_id                    INT NOT NULL
)
GO