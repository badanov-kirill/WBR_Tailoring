CREATE TABLE [Planing].[CoveringReserv]
(
	cr_id           INT IDENTITY(1, 1) CONSTRAINT [PK_CoveringReserv] PRIMARY KEY CLUSTERED NOT NULL,
	covering_id     INT CONSTRAINT [FK_CoveringReserv_covering_id] FOREIGN KEY REFERENCES Planing.Covering(covering_id) NOT NULL,
	spcvc_id        INT CONSTRAINT [FK_CoveringReserv_spcvc_id] FOREIGN KEY REFERENCES Planing.SketchPlanColorVariantCompleting(spcvc_id) NOT NULL,
	shkrm_id        INT CONSTRAINT [FK_CoveringReserv_shkrm_id] FOREIGN KEY REFERENCES Warehouse.SHKRawMaterial(shkrm_id) NOT NULL,
	okei_id         INT CONSTRAINT [FK_CoveringReserv_okei_id] FOREIGN KEY REFERENCES Qualifiers.OKEI(okei_id) NOT NULL,
	qty             DECIMAL(9, 3) NOT NULL,
	dt              DATETIME2(0) NOT NULL,
	employee_id     INT NOT NULL,
	pre_cost        DECIMAL(9, 2) NULL
)

GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_CoveringReserv_covering_id_id_spcvc_id_shkrm_id] ON Planing.CoveringReserv(covering_id, spcvc_id, shkrm_id) ON [Indexes]