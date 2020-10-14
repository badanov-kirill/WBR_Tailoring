CREATE TABLE [Logistics].[TTNDivergenceAct]
(
	ttnda_id                       INT IDENTITY(1, 1) CONSTRAINT [PK_TTNDivergenceAct] PRIMARY KEY CLUSTERED NOT NULL,
	create_employee_id             INT NOT NULL,
	create_dt                      dbo.SECONDSTIME NOT NULL,
	ttn_id                         INT CONSTRAINT [FK_TTNDivergenceAct_ttn_id] FOREIGN KEY REFERENCES Logistics.TTN(ttn_id) NOT NULL,
	shkrm_id                       INT CONSTRAINT [FK_TTNDivergenceAct_shkrm_id] FOREIGN KEY REFERENCES Warehouse.SHKRawMaterial(shkrm_id) NULL,
	rmt_id                         INT CONSTRAINT [FK_TTNDivergenceAct_rmt_id] FOREIGN KEY REFERENCES Material.RawMaterialType(rmt_id) NULL,
	art_id                         INT CONSTRAINT [FK_TTNDivergenceAct_art_id] FOREIGN KEY REFERENCES Material.Article(art_id) NULL,
	okei_id                        INT CONSTRAINT [FK_TTNDivergenceAct_okei_id] FOREIGN KEY REFERENCES Qualifiers.OKEI(okei_id) NULL,
	stor_unit_residues_okei_id     INT CONSTRAINT [FK_TTNDivergenceAct_stor_unit_res_okei_id] FOREIGN KEY REFERENCES Qualifiers.OKEI(okei_id) NOT NULL,
	stor_unit_residues_qty         DECIMAL(9, 3) NOT NULL,
	nds                            TINYINT CONSTRAINT [FK_TTNDivergenceAct_nds] FOREIGN KEY REFERENCES RefBook.NDS(nds) NOT NULL,
	gross_mass                     INT NOT NULL,
	divergence_qty                 DECIMAL(9, 3) NOT NULL,
	comment                        VARCHAR(200) NULL,
	write_of_qty                   DECIMAL(9, 3) NULL,
	write_of_employee_id           INT NULL,
	write_of_dt                    dbo.SECONDSTIME NULL,
	write_of_comment               VARCHAR(500) NULL,
	complite_employee_id           INT NULL,
	complite_dt                    dbo.SECONDSTIME NULL,
)

GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_TTNDivergenceAct_ttn_id_shkrm_id] ON Logistics.TTNDivergenceAct(ttn_id, shkrm_id) ON [Indexes]