CREATE TABLE [Material].[RawMaterialTypeTerminalResidues]
(
	rmt_id                     INT CONSTRAINT [FK_RawMaterialTypeTerminalResidues_rmt_id] FOREIGN KEY REFERENCES Material.RawMaterialType(rmt_id) NOT NULL,
	stor_unit_residues_qty     DECIMAL(9, 3) CONSTRAINT [CH_RawMaterialTypeTerminalResidues_stor_unit_res_qty] CHECK(stor_unit_residues_qty > 0) NOT NULL,
	dt                         DATETIME2(0) NOT NULL,
	employee_id                INT NOT NULL,
	CONSTRAINT [PK_RawMaterialTypeTerminalResidues] PRIMARY KEY CLUSTERED(rmt_id)
)
