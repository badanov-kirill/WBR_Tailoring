CREATE TABLE [Material].[RawMaterialTypeStuffModel]
(
	rmt_id             INT CONSTRAINT [FK_RawMaterialTypeStuffModel_rmt_id] FOREIGN KEY REFERENCES Material.RawMaterialType(rmt_id) NOT NULL,
	stuff_model_id     INT NOT NULL,
	dt                 DATETIME2(0) NOT NULL,
	employee_id        INT NOT NULL,
	CONSTRAINT [PK_RawMaterialTypeStuffModel] PRIMARY KEY CLUSTERED(rmt_id)
)
