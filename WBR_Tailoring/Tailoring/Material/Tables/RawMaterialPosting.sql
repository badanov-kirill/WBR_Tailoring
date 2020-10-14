CREATE TABLE [Material].[RawMaterialPosting]
(
	doc_id                         INT NOT NULL,
	doc_type_id                    TINYINT NOT NULL,
	rmt_id                         INT CONSTRAINT [FK_RawMaterialPosting_rmt_id] FOREIGN KEY REFERENCES Material.RawMaterialType(rmt_id) NOT NULL,
	art_id                         INT CONSTRAINT [FK_RawMaterialPosting_art_id] FOREIGN KEY REFERENCES Material.Article(art_id) NOT NULL,
	color_id                       INT CONSTRAINT [FK_RawMaterialPosting_color_id] FOREIGN KEY REFERENCES Material.ClothColor(color_id) NOT NULL,
	suppliercontract_id            INT CONSTRAINT [FK_RawMaterialPosting_suppliercontract_id] FOREIGN KEY REFERENCES Suppliers.SupplierContract(suppliercontract_id) NOT 
	NULL,
	su_id                          INT CONSTRAINT [FK_RawMaterialPosting_su_id] FOREIGN KEY REFERENCES RefBook.SpaceUnit(su_id) NOT NULL,
	okei_id                        INT CONSTRAINT [FK_RawMaterialPosting_okei_id] FOREIGN KEY REFERENCES Qualifiers.OKEI(okei_id) NOT NULL,
	qty                            DECIMAL(9, 2) NOT NULL,
	stor_unit_residues_okei_id     INT CONSTRAINT [FK_RawMaterialPosting_stor_unit_residues_okei_id] FOREIGN KEY REFERENCES Qualifiers.OKEI(okei_id) NOT NULL,
	stor_unit_residues_qty         DECIMAL(9, 2) NOT NULL,
	amount                         DECIMAL(19, 8) NOT NULL,
	nds                            TINYINT NOT NULL,
	dt                             dbo.SECONDSTIME NOT NULL,
	employee_id                    INT NOT NULL,
	is_deleted                     BIT NOT NULL,
	shkrm_id                       INT CONSTRAINT [FK_RawMaterialPosting] FOREIGN KEY REFERENCES Warehouse.SHKRawMaterial(shkrm_id) NOT NULL,
	CONSTRAINT [PK_RawMaterialPosting] PRIMARY KEY CLUSTERED(doc_id, doc_type_id),
	CONSTRAINT [FK_RawMaterialPosting_doc_id_doc_type_id] FOREIGN KEY(doc_type_id, doc_id) REFERENCES Documents.DocumentID(doc_type_id, doc_id),
	CONSTRAINT [CH_RawMaterialPosting_doc_type_id] CHECK(doc_type_id = 2)
)
