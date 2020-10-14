CREATE TABLE [SyncFinance].[RawMaterialTypeVariantUpload]
(
	rmtv_id          INT CONSTRAINT [FK_RawMaterialTypeVariantUpload_rmt_id] FOREIGN KEY REFERENCES Material.RawMaterialTypeVariant(rmtv_id) NOT NULL,
	dt              DATETIME2(0) NOT NULL,
	employee_id     INT NOT NULL,
	rv              ROWVERSION NOT NULL,
	CONSTRAINT [PK_RawMaterialTypeVariantUpload] PRIMARY KEY CLUSTERED(rmtv_id)
)