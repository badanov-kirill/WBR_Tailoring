CREATE TABLE [Material].[CompletingRawMaterial]
(
	completing_id     INT CONSTRAINT [FK_CompletingRawMaterial_completing_id] FOREIGN KEY REFERENCES Material.Completing(completing_id) NOT NULL,
	rmt_id            INT CONSTRAINT [FK_CompletingRawMaterial_rmt_id] FOREIGN KEY REFERENCES Material.RawMaterialType(rmt_id) NOT NULL,
	CONSTRAINT [PK_CompletingRawMaterial] PRIMARY KEY CLUSTERED(completing_id, rmt_id)
)
