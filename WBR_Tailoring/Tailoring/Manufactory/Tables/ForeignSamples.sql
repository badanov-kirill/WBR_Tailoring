CREATE TABLE [Manufactory].[ForeignSamples]
(
	fs_id           INT IDENTITY(1, 1) CONSTRAINT [PK_ForeignSamples] PRIMARY KEY CLUSTERED NOT NULL,
	ct_id           INT CONSTRAINT [FK_ForeignSamples_ct_id] FOREIGN KEY REFERENCES Material.ClothType(ct_id) NOT NULL,
	contents        VARCHAR(100) NULL,
	article         VARCHAR(50) NOT NULL,
	ts_id           INT CONSTRAINT [FK_ForeignSamples_ts_id] FOREIGN KEY REFERENCES Products.TechSize(ts_id) NOT NULL,
	brand_id        INT CONSTRAINT [FK_ForeignSamples_brand_id] FOREIGN KEY REFERENCES Products.Brand(brand_id) NOT NULL,
	color_cod       INT CONSTRAINT [FK_ForeignSamples_color_id] FOREIGN KEY REFERENCES Products.Color(color_cod) NULL,
	comment         VARCHAR(500) NULL,
	shkrm_id        INT CONSTRAINT [FK_ForeignSamples_shkrm_id] FOREIGN KEY REFERENCES Warehouse.SHKRawMaterial(shkrm_id) NULL,
	dt              DATETIME2(0) NOT NULL,
	employee_id     INT NOT NULL
)

GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_ForeignSamples_shkrm_id] ON [Manufactory].[ForeignSamples](shkrm_id) WHERE shkrm_id IS NOT NULL ON [Indexes]