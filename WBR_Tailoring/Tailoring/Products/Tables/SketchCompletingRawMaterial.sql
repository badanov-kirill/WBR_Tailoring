CREATE TABLE [Products].[SketchCompletingRawMaterial]
(
	scrm_id         INT IDENTITY(1, 1) CONSTRAINT [PK_SketchCompletingRawMaterial] PRIMARY KEY CLUSTERED NOT NULL,
	sc_id           INT CONSTRAINT [FK_SketchCompletingRawMaterial_sc_id] FOREIGN KEY REFERENCES Products.SketchCompleting(sc_id) NOT NULL,
	rmt_id          INT CONSTRAINT [FK_SketchCompletingRawMaterial_rmt_id] FOREIGN KEY REFERENCES Material.RawMaterialType(rmt_id) NOT NULL,
	dt              dbo.SECONDSTIME NOT NULL,
	employee_id     INT NOT NULL
)

GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_SketchCompletingRawMaterial_sc_id_rmt_id] ON Products.SketchCompletingRawMaterial(sc_id, rmt_id) ON [Indexes]
