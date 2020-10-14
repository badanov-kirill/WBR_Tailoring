CREATE TABLE [Planing].[PlanShippingDetail]
(
	psd_id                         INT IDENTITY(1, 1) CONSTRAINT [PK_PlanShippingDetail] PRIMARY KEY CLUSTERED NOT NULL,
	ps_id                          INT CONSTRAINT [FK_PlanShippingDetail_ps_id] FOREIGN KEY REFERENCES Planing.PlanShipping(ps_id) NOT NULL,
	shkrm_id                       INT CONSTRAINT [FK_PlanShippingDetail_shkrm_id] FOREIGN KEY REFERENCES Warehouse.SHKRawMaterial(shkrm_id) NOT NULL,
	stor_unit_residues_okei_id     INT CONSTRAINT [FK_PlanShippingDetail_stor_unit_res_okei_id] FOREIGN KEY REFERENCES Qualifiers.OKEI(okei_id) NOT NULL,
	stor_unit_residues_qty         DECIMAL(9, 3) NOT NULL,
	employee_id                    INT NOT NULL,
	dt                             DATETIME2(0) NOT NULL,
	shipping_dt                    DATETIME2(0) NULL,
	gross_mass                     INT NOT NULL,
	ttnd_id                        INT CONSTRAINT [FK_PlanShippingDetail] FOREIGN KEY REFERENCES Logistics.TTNDetail(ttnd_id) NULL
)

GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_PlanShippingDetail_shkrm_id] ON Planing.PlanShippingDetail(shkrm_id) WHERE shipping_dt IS NULL ON [Indexes]

GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_PlanShippingDetail_ps_id_shkrm_id] ON Planing.PlanShippingDetail(ps_id, shkrm_id) ON [Indexes]