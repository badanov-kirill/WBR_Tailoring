CREATE TABLE [Material].[RawMaterialExchangeDetailChange]
(
	rmed_id                        INT IDENTITY(1, 1) CONSTRAINT [PK_RawMaterialExchangeDetail] PRIMARY KEY CLUSTERED NOT NULL,
	rme_id                         INT CONSTRAINT [FK_RawMaterialExchangeDetail_rme_id] FOREIGN KEY REFERENCES Material.RawMaterialExchange(rme_id) NOT NULL,
	shkrm_id                       INT CONSTRAINT [FK_RawMaterialExchangeDetail_shkrm_id] FOREIGN KEY REFERENCES Warehouse.SHKRawMaterial(shkrm_id) NOT NULL,
	rmt_id                         INT CONSTRAINT [FK_RawMaterialExchangeDetail_rmt_id] FOREIGN KEY REFERENCES Material.RawMaterialType(rmt_id) NOT NULL,
	art_id                         INT CONSTRAINT [FK_RawMaterialExchangeDetail_art_id] FOREIGN KEY REFERENCES Material.Article(art_id) NOT NULL,
	color_id                       INT CONSTRAINT [FK_RawMaterialExchangeDetail_color_id] FOREIGN KEY REFERENCES Material.ClothColor(color_id) NOT NULL,
	su_id                          INT CONSTRAINT [FK_RawMaterialExchangeDetail_su_id] FOREIGN KEY REFERENCES RefBook.SpaceUnit(su_id) NOT NULL,
	okei_id                        INT CONSTRAINT [FK_RawMaterialExchangeDetail_okei_id] FOREIGN KEY REFERENCES Qualifiers.OKEI(okei_id) NOT NULL,
	qty                            DECIMAL(9, 2) NOT NULL,
	stor_unit_residues_okei_id     INT CONSTRAINT [FK_RawMaterialExchangeDetail_stor_unit_residues_okei_id] FOREIGN KEY REFERENCES Qualifiers.OKEI(okei_id) 
	NOT NULL,
	stor_unit_residues_qty         DECIMAL(9, 2) NOT NULL,
	frame_width                    SMALLINT NOT NULL,
	is_defected                    BIT NOT NULL,
	dt                             DATETIME2(0) NOT NULL,
	employee_id                    INT NOT NULL
)
