CREATE TABLE [Material].[RawMaterialTypePhoto]
(
	rmtp_id         INT IDENTITY(1, 1) CONSTRAINT [PK_RawMaterialTypePhoto] PRIMARY KEY CLUSTERED NOT NULL,
	rmt_id          INT CONSTRAINT [FK_RawMaterialPhoto_rmt_id] FOREIGN KEY REFERENCES Material.RawMaterialType(rmt_id) NOT NULL,
	art_id          INT CONSTRAINT [FK_RawMaterialPhoto_art_id] FOREIGN KEY REFERENCES Material.Article(art_id) NULL,
	color_id        INT CONSTRAINT [FK_RawMaterialPhoto_color_id] FOREIGN KEY REFERENCES Material.ClothColor(color_id) NOT NULL,
	frame_width     SMALLINT NULL,
	supplier_id     INT CONSTRAINT [FK_RawMaterialPhoto_supplier_id] FOREIGN KEY REFERENCES Suppliers.Supplier(supplier_id) NOT NULL,
	dt              DATETIME2(0) NOT NULL,
	employee_id     INT NOT NULL
)

GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_RawMaterialTypePhoto_rmt_id_art_id_color_id_frame_width_supplier_id] ON Material.RawMaterialTypePhoto(rmt_id, art_id, color_id, frame_width, supplier_id) 
ON [Indexes]
