CREATE TABLE [Logistics].[TTNDetail]
(
	ttnd_id                        INT IDENTITY(1, 1) CONSTRAINT [PK_TTNDeatail] PRIMARY KEY CLUSTERED NOT NULL,
	ttn_id                         INT CONSTRAINT [FK_TTNDetail_ttn_id] FOREIGN KEY REFERENCES Logistics.TTN(ttn_id) NOT NULL,
	shkrm_id                       INT CONSTRAINT [FK_TTNDetail_shkrm_id] FOREIGN KEY REFERENCES Warehouse.SHKRawMaterial(shkrm_id) NOT NULL,
	rmt_id                         INT CONSTRAINT [FK_TTNDetail_rmt_id] FOREIGN KEY REFERENCES Material.RawMaterialType(rmt_id) NOT NULL,
	art_id                         INT CONSTRAINT [FK_TTNDetail_art_id] FOREIGN KEY REFERENCES Material.Article(art_id) NOT NULL,
	okei_id                        INT CONSTRAINT [FK_TTNDetail_okei_id] FOREIGN KEY REFERENCES Qualifiers.OKEI(okei_id) NOT NULL,
	qty                            DECIMAL(9, 3) NOT NULL,
	stor_unit_residues_okei_id     INT CONSTRAINT [FK_TTNDetail_stor_unit_res_okei_id] FOREIGN KEY REFERENCES Qualifiers.OKEI(okei_id) NOT NULL,
	stor_unit_residues_qty         DECIMAL(9, 3) NOT NULL,
	employee_id                    INT NOT NULL,
	dt                             dbo.SECONDSTIME NOT NULL,
	complite_qty                   DECIMAL(9, 3) NULL,
	complite_employee_id           INT NULL,
	complite_dt                    dbo.SECONDSTIME NULL,
	nds                            TINYINT CONSTRAINT [FK_TTNDetail_nds] FOREIGN KEY REFERENCES RefBook.NDS(nds) NOT NULL,
	gross_mass                     INT NOT NULL,
	su_id                          INT CONSTRAINT [FK_TTNDetail_su_id] FOREIGN KEY REFERENCES RefBook.SpaceUnit(su_id) NOT NULL
)

GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_TTNDetail_ttn_id_shkrm_id] ON Logistics.TTNDetail(ttn_id, shkrm_id) ON [Indexes]
GO
CREATE NONCLUSTERED INDEX [IX_TTNDetail_shkrm_id] ON Logistics.TTNDetail(shkrm_id) ON [Indexes]
GO
CREATE NONCLUSTERED INDEX [IX_TTNDetail_complete_dt] ON Logistics.TTNDetail (complite_dt) ON [Indexes]