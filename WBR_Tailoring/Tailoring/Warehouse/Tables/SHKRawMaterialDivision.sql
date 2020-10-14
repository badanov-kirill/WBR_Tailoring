CREATE TABLE [Warehouse].[SHKRawMaterialDivision]
(
	srmd_id                        INT IDENTITY(1, 1) CONSTRAINT [PK_SHKRawMaterialDivision] PRIMARY KEY CLUSTERED NOT NULL,
	src_shkrm_id                   INT CONSTRAINT [FK_SHKRawMaterialDivision_src_shkrm_id] FOREIGN KEY REFERENCES Warehouse.SHKRawMaterial(shkrm_id) NOT NULL,
	dst_shkrm_id                   INT CONSTRAINT [FK_SHKRawMaterialDivision_dst_shkrm_id] FOREIGN KEY REFERENCES Warehouse.SHKRawMaterial(shkrm_id) NOT NULL,
	stor_unit_residues_qty         DECIMAL(9, 3) NOT NULL,
	stor_unit_residues_okei_id     INT CONSTRAINT [FK_SHKRawMaterialDivision_stor_unit_residues_okei_id] FOREIGN KEY REFERENCES Qualifiers.OKEI(okei_id) NOT NULL,
	dt                             DATETIME2(0) NOT NULL,
	employee_id                    INT NOT NULL,
)

GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_SHKRawMaterialDivision_src_shkrm_id_dst_shkrm_id] ON Warehouse.SHKRawMaterialDivision(src_shkrm_id, dst_shkrm_id) ON 
[Indexes]