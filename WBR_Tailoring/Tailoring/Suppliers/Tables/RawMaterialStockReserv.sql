CREATE TABLE [Suppliers].[RawMaterialStockReserv]
(
	rmsr_id         INT IDENTITY(1, 1) CONSTRAINT [PK_RawMaterialStockReserv] PRIMARY KEY CLUSTERED NOT NULL,
	rms_id          INT CONSTRAINT [FK_RawMaterialStockReserv_rms_id] FOREIGN KEY REFERENCES Suppliers.RawMaterialStock(rms_id) NOT NULL,
	spcvc_id        INT CONSTRAINT [FK_RawMaterialStockReserv_spcvc_id] FOREIGN KEY REFERENCES Planing.SketchPlanColorVariantCompleting(spcvc_id) NOT NULL,
	qty             DECIMAL(15, 3) NOT NULL,
	dt              dbo.SECONDSTIME NOT NULL,
	employee_id     INT NOT NULL
)

GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_RawMaterialStockReserv_rms_id_spcvc_id] ON Suppliers.RawMaterialStockReserv(rms_id, spcvc_id) ON [Indexes]
GO
CREATE NONCLUSTERED INDEX [IX_RawMaterialStockReserv_spcvc_id] ON Suppliers.RawMaterialStockReserv (spcvc_id) ON [Indexes]