CREATE TABLE [Settings].[LabelBrand]
(
	brand_id     INT CONSTRAINT [FK_LabelBrand_brand_id] FOREIGN KEY REFERENCES Products.Brand(brand_id) NOT NULL,
	lb_type      CHAR(1) NOT NULL,
	rmt_id       INT CONSTRAINT [FK_LabelBrand_rmt_id] FOREIGN KEY REFERENCES Material.RawMaterialType(rmt_id) NOT NULL,
	qty          DECIMAL(9, 3) NOT NULL
	CONSTRAINT [PK_LabelBrand] PRIMARY KEY CLUSTERED(brand_id, lb_type)
)
