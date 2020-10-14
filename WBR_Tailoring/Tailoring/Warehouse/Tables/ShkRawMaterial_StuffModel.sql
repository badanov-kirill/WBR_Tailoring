CREATE TABLE [Warehouse].[ShkRawMaterial_StuffModel]
(
	shkrm_id                INT NOT NULL CONSTRAINT [FK_ShkRawMaterial_StuffModel_shkrm_id] FOREIGN KEY REFERENCES Warehouse.SHKRawMaterial(shkrm_id),
	stuff_shk_id            INT NOT NULL,
	stuff_model_id          INT NOT NULL,
	manufactured_number     VARCHAR(20) NULL,
	dt                      DATETIME2(0) NOT NULL,
	employee_id             INT NOT NULL,
	CONSTRAINT [PK_ShkRawMaterial_StuffModel] PRIMARY KEY CLUSTERED(shkrm_id ASC)
)
