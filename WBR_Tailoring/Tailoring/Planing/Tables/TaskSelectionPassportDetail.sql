CREATE TABLE [Planing].[TaskSelectionPassportDetail]
(
	tspd_id                 INT IDENTITY(1, 1) CONSTRAINT [PK_TaskSelectionPassportDetail] PRIMARY KEY CLUSTERED NOT NULL,
	tsp_id                  INT CONSTRAINT [FK_TaskSelectionPassportDetail_tsp_id] FOREIGN KEY REFERENCES Planing.TaskSelectionPassport(tsp_id) NOT NULL,
	shkrm_id                INT CONSTRAINT [FK_TaskSelectionPassportDetail_shkrm_id] FOREIGN KEY REFERENCES Warehouse.SHKRawMaterial(shkrm_id) NOT NULL,
	suppliercontract_id     INT CONSTRAINT [FK_TaskSelectionPassportDetail_supcontr_id] FOREIGN KEY REFERENCES Suppliers.SupplierContract(suppliercontract_id) NOT 
	NULL,
	rmt_id                  INT CONSTRAINT [FK_TaskSelectionPassportDetail_rmt_id] FOREIGN KEY REFERENCES Material.RawMaterialType(rmt_id) NOT NULL,
	art_id                  INT CONSTRAINT [FK_TaskSelectionPassportDetail_art_id] FOREIGN KEY REFERENCES Material.Article(art_id) NOT NULL,
	color_id                INT CONSTRAINT [FK_TaskSelectionPassportDetail_color_id] FOREIGN KEY REFERENCES Material.ClothColor(color_id) NOT NULL,
	frame_width             SMALLINT NULL,
	employee_id             INT NOT NULL,
	dt                      DATETIME2(0) NOT NULL,
	quantity                DECIMAL(9, 3) NOT NULL,
	okei_id                 INT NOT NULL
)

GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_TaskSelectionPassportDetail_tsp_id_shkrm_id] ON Planing.TaskSelectionPassportDetail(tsp_id, shkrm_id) ON [Indexes]