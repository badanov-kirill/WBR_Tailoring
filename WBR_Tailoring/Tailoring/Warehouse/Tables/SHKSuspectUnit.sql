CREATE TABLE [Warehouse].[SHKSuspectUnit]
(
	shks_id         INT NOT NULL CONSTRAINT [FK_SHKSuspectUnit_shks_id] FOREIGN KEY REFERENCES Warehouse.SHKSuspect(shks_id),
	descript        VARCHAR(900) NOT NULL,
	shksu_id        INT NOT NULL CONSTRAINT [FK_SHKSuspectUnit_shksu_id] FOREIGN KEY REFERENCES Warehouse.SHKSpaceUnit(shksu_id),
	okei_id         INT NOT NULL CONSTRAINT [FK_SHKSuspectUnit_okei_id] FOREIGN KEY REFERENCES Qualifiers.OKEI(okei_id),
	qty             DECIMAL(9, 3) NOT NULL,
	dt              DATETIME2(0) NOT NULL,
	employee_id     INT NOT NULL,
	CONSTRAINT [PK_SHKSuspectUnit] PRIMARY KEY CLUSTERED(shks_id ASC)
)
GO