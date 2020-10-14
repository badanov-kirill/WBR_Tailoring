CREATE TABLE [Warehouse].[SHKRawMaterialPhoto]
(
	srmp_id INT IDENTITY(1,1) CONSTRAINT [PK_SHKRawMaterialPhoto] PRIMARY KEY CLUSTERED NOT NULL,
	shkrm_id INT CONSTRAINT [FK_SHKRawMaterialPhoto_shkrm_id] FOREIGN KEY REFERENCES Warehouse.SHKRawMaterial(shkrm_id) NOT NULL,
	employee_id INT NOT NULL,
	dt DATETIME2(0) NOT NULL,
	rmtp_id INT CONSTRAINT [FK_SHKRawMaterialPhoto_rmtp_id] FOREIGN KEY REFERENCES Material.RawMaterialTypePhoto(rmtp_id) NOT NULL
)
