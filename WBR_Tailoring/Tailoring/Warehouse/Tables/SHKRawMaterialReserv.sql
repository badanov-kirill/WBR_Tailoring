CREATE TABLE [Warehouse].[SHKRawMaterialReserv]
(
	shkrm_id        INT NOT NULL CONSTRAINT [FK_SHKRawMaterialReserv_shkrm_id] FOREIGN KEY REFERENCES Warehouse.SHKRawMaterialActualInfo(shkrm_id),
	spcvc_id        INT NOT NULL CONSTRAINT [FK_SHKRawMaterialReserv_spcvc_id] FOREIGN KEY REFERENCES Planing.SketchPlanColorVariantCompleting(spcvc_id),
	okei_id         INT NULL CONSTRAINT [FK_SHKRawMaterialReserv_okei_id] FOREIGN KEY REFERENCES Qualifiers.OKEI(okei_id),
	quantity        DECIMAL(9, 3) NOT NULL,
	dt              DATETIME2(0) NOT NULL,
	employee_id     INT NOT NULL,
	rmid_id         INT NULL CONSTRAINT [FK_SHKRawMaterialReserv_rmid_id] FOREIGN KEY REFERENCES Material.RawMaterialIncomeDetail(rmid_id),
	rmodr_id        INT NULL CONSTRAINT [FK_SHKRawMaterialReserv_rmodr_id] FOREIGN KEY REFERENCES Suppliers.RawMaterialOrderDetailFromReserv(rmodr_id),
	CONSTRAINT [PK_SHKRawMaterialReserv] PRIMARY KEY CLUSTERED(shkrm_id, spcvc_id),
	CONSTRAINT [CK_SHKRawMaterialReserv_quantity] CHECK (quantity > 0)
)	

GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_SHKRawMaterialReserv_shkrm_id_spcvc_id] ON Warehouse.SHKRawMaterialReserv(shkrm_id, spcvc_id) ON [Indexes]
GO
CREATE NONCLUSTERED INDEX [IX_SHKRawMaterialReserv_spcvc_id] ON Warehouse.SHKRawMaterialReserv (spcvc_id) ON [Indexes]