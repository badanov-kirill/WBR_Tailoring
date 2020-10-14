CREATE TABLE [SyncFinance].[RawMaterialTypeUpload]
(
	rmt_id          INT CONSTRAINT [FK_RawMaterialTypeUpload_rmt_id] FOREIGN KEY REFERENCES Material.RawMaterialType(rmt_id) NOT NULL,
	dt              DATETIME2(0) NOT NULL,
	employee_id     INT NOT NULL,
	rv              ROWVERSION NOT NULL,
	CONSTRAINT [PK_RawMaterialTypeUpload] PRIMARY KEY CLUSTERED(rmt_id)
)
