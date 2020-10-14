CREATE TABLE [Warehouse].[SHKRawMaterialDefectDescr]
(
	shkrm_id        INT NOT NULL CONSTRAINT [FK_SHKRawMaterialDefectDescr_shkrm_id] FOREIGN KEY REFERENCES Warehouse.SHKRawMaterial(shkrm_id),
	descr           VARCHAR(900) NOT NULL,
	okei_id         INT NOT NULL CONSTRAINT [FK_SHKRawMaterialDefectDescr_okei_id] FOREIGN KEY REFERENCES Qualifiers.OKEI(okei_id),
	qty             DECIMAL(9, 3) NOT NULL,	
	dt              DATETIME2(0) NOT NULL,
	employee_id     INT NOT NULL,
	CONSTRAINT [PK_SHKRawMaterialDefectDescr] PRIMARY KEY CLUSTERED(shkrm_id ASC)
)
GO
