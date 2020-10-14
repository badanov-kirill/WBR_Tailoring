CREATE TABLE [Planing].[PreCostReserv]
(
	ccr_id          INT IDENTITY(1, 1) CONSTRAINT [PK_PreCostReserv] PRIMARY KEY CLUSTERED NOT NULL,
	spcvc_id        INT CONSTRAINT [FK_PreCostReserv_spcvc_id] FOREIGN KEY REFERENCES Planing.SketchPlanColorVariantCompleting(spcvc_id) NOT NULL,
	shkrm_id        INT CONSTRAINT [FK_PreCostReserv_shkrm_id] FOREIGN KEY REFERENCES Warehouse.SHKRawMaterial(shkrm_id) NOT NULL,
	okei_id         INT CONSTRAINT [FK_PreCostReserv_okei_id] FOREIGN KEY REFERENCES Qualifiers.OKEI(okei_id) NOT NULL,
	qty             DECIMAL(9, 3) NOT NULL,
	dt              DATETIME2(0) NOT NULL,
	employee_id     INT NOT NULL,
	pre_cost        DECIMAL(9, 2) NULL
)

GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_PreCostReserv_spcv_id_id_spcvc_id_shkrm_id] ON Planing.PreCostReserv(spcvc_id, shkrm_id) ON [Indexes]