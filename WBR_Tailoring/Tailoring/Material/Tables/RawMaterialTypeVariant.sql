CREATE TABLE [Material].[RawMaterialTypeVariant]
(
	rmtv_id         INT IDENTITY(1, 1) CONSTRAINT [PK_RawMaterialTypeVariant] PRIMARY KEY CLUSTERED NOT NULL,
	rmt_id          INT CONSTRAINT [FK_RawMaterialType_rmt_id] FOREIGN KEY REFERENCES Material.RawMaterialType(rmt_id) NOT NULL,
	art_id          INT CONSTRAINT [FK_RawMaterialType_art_id] FOREIGN KEY REFERENCES Material.Article(art_id) NULL,
	frame_width     SMALLINT NULL,
	rmt_astra_id	INT NULL
)

GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_RawMaterialTypeVariant_rmt_id_art_id_frame_width] ON Material.RawMaterialTypeVariant(rmt_id, art_id, frame_width) ON [Indexes]

GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_RawMaterialTypeVariant_rmt_astra_id] ON Material.RawMaterialTypeVariant(rmt_astra_id) WHERE rmt_astra_id IS NOT NULL ON [Indexes]