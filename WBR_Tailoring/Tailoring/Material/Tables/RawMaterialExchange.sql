CREATE TABLE [Material].[RawMaterialExchange]
(
	rme_id                         INT IDENTITY(1, 1) CONSTRAINT [PK_RawMaterialExchange] PRIMARY KEY CLUSTERED NOT NULL,
	doc_id                         INT NOT NULL,
	doc_type_id                    TINYINT NOT NULL,
	create_dt                      DATETIME2(0) NOT NULL,
	create_employee_id             INT NOT NULL,
	return_dt                      DATETIME2(0) NULL,
	return_employee_id             INT NULL,
	change_dt                      DATETIME2(0) NULL,
	change_employee_id             INT NULL,
	rmid_id                        INT NOT NULL,
	shkrm_id                       INT CONSTRAINT [FK_RawMaterialExchange_shkrm_id] FOREIGN KEY REFERENCES Warehouse.SHKRawMaterial(shkrm_id) NOT NULL,
	rmt_id                         INT CONSTRAINT [FK_RawMaterialExchange_rmt_id] FOREIGN KEY REFERENCES Material.RawMaterialType(rmt_id) NOT NULL,
	art_id                         INT CONSTRAINT [FK_RawMaterialExchange_art_id] FOREIGN KEY REFERENCES Material.Article(art_id) NOT NULL,
	color_id                       INT CONSTRAINT [FK_RawMaterialExchange_color_id] FOREIGN KEY REFERENCES Material.ClothColor(color_id) NOT NULL,
	suppliercontract_id            INT CONSTRAINT [FK_RawMaterialExchange_suppliercontract_id] FOREIGN KEY REFERENCES Suppliers.SupplierContract(suppliercontract_id) 
	NOT NULL,
	su_id                          INT CONSTRAINT [FK_RawMaterialExchange_su_id] FOREIGN KEY REFERENCES RefBook.SpaceUnit(su_id) NOT NULL,
	okei_id                        INT CONSTRAINT [FK_RawMaterialExchange_okei_id] FOREIGN KEY REFERENCES Qualifiers.OKEI(okei_id) NOT NULL,
	qty                            DECIMAL(9, 2) NOT NULL,
	stor_unit_residues_okei_id     INT CONSTRAINT [FK_RawMaterialExchange_stor_unit_residues_okei_id] FOREIGN KEY REFERENCES Qualifiers.OKEI(okei_id) NOT NULL,
	stor_unit_residues_qty         DECIMAL(9, 2) NOT NULL,
	shksu_id                       INT CONSTRAINT [FK_RawMaterialExchange_shksu_id] FOREIGN KEY REFERENCES Warehouse.SHKSpaceUnit(shksu_id) NOT NULL,
	frame_width                    SMALLINT NULL,
	is_defected                    BIT NOT NULL,
	need_rmt_id                    INT CONSTRAINT [FK_RawMaterialExchange_need_rmt_id] FOREIGN KEY REFERENCES Material.RawMaterialType(rmt_id) NOT NULL,
	need_art_id                    INT CONSTRAINT [FK_RawMaterialExchange_need_art_id] FOREIGN KEY REFERENCES Material.Article(art_id) NOT NULL,
	need_color_id                  INT CONSTRAINT [FK_RawMaterialExchange_need_color_id] FOREIGN KEY REFERENCES Material.ClothColor(color_id) NOT NULL,
	need_okei_id                   INT CONSTRAINT [FK_RawMaterialExchange_need_okei_id] FOREIGN KEY REFERENCES Qualifiers.OKEI(okei_id) NOT NULL,
	need_qty                       DECIMAL(9, 2) NOT NULL,
	nds                            TINYINT NOT NULL,
	dt                             DATETIME2(0) NOT NULL,
	employee_id                    INT NOT NULL,
	CONSTRAINT [FK_RawMaterialExchange_doc_id_doc_type_id] FOREIGN KEY(doc_type_id, doc_id) REFERENCES Documents.DocumentID(doc_type_id, doc_id),
	CONSTRAINT [CH_RawMaterialExchange_doc_type_id] CHECK(doc_type_id = 1)
)

GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_RawMaterialExchange_base_shkrm_id] ON Material.RawMaterialExchange(shkrm_id) ON [Indexes] 
