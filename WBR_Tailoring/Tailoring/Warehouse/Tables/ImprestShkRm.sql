CREATE TABLE [Warehouse].[ImprestShkRM]
(
	isr_id                         INT IDENTITY(1, 1) CONSTRAINT [PK_ImprestShkRM] PRIMARY KEY CLUSTERED NOT NULL,
	imprest_id                     INT CONSTRAINT [FK_ImprestShkRM_imprest_id] FOREIGN KEY REFERENCES Warehouse.Imprest(imprest_id) NOT NULL,
	shkrm_id                       INT CONSTRAINT [FK_ImprestShkRM_shkrm_id] FOREIGN KEY REFERENCES Warehouse.SHKRawMaterial(shkrm_id) NOT NULL,
	doc_id                         INT NOT NULL,
	doc_type_id                    TINYINT CONSTRAINT [FK_ImprestShkRM_doc_type_id] FOREIGN KEY REFERENCES Documents.DocumentType(doc_type_id) NOT NULL,
	rmt_id                         INT CONSTRAINT [FK_ImprestShkRM_rmt_id] FOREIGN KEY REFERENCES Material.RawMaterialType(rmt_id) NOT NULL,
	art_id                         INT CONSTRAINT [FK_ImprestShkRM_art_id] FOREIGN KEY REFERENCES Material.Article(art_id) NOT NULL,
	color_id                       INT CONSTRAINT [FK_ImprestShkRM_color_id] FOREIGN KEY REFERENCES Material.ClothColor(color_id) NOT NULL,
	su_id                          INT CONSTRAINT [FK_ImprestShkRM_su_id] FOREIGN KEY REFERENCES RefBook.SpaceUnit(su_id) NOT NULL,
	suppliercontract_id            INT CONSTRAINT [FK_ImprestShkRM_suppliercontract_id] FOREIGN KEY REFERENCES Suppliers.SupplierContract(suppliercontract_id) NOT 
	NULL,
	okei_id                        INT CONSTRAINT [FK_ImprestShkRM_okei_id] FOREIGN KEY REFERENCES Qualifiers.OKEI(okei_id) NOT NULL,
	qty                            DECIMAL(9, 3) NOT NULL,
	stor_unit_residues_okei_id     INT CONSTRAINT [FK_ImprestShkRM_stor_unit_residues_okei_id] FOREIGN KEY REFERENCES Qualifiers.OKEI(okei_id) NOT NULL,
	stor_unit_residues_qty         DECIMAL(9, 3) NOT NULL,
	nds                            TINYINT NOT NULL,
	dt                             dbo.SECONDSTIME NOT NULL,
	employee_id                    INT NOT NULL,
	frame_width                    SMALLINT NULL,
	is_defected                    BIT NOT NULL,
	amount                         DECIMAL(15, 2) NULL
)

GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_ImprestShkRM_shkrm_id] ON Warehouse.ImprestShkRM(shkrm_id) ON [Indexes]