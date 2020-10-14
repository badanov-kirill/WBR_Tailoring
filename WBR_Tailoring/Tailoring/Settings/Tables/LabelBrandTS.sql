CREATE TABLE [Settings].[LabelBrandTS]
(
	brand_id INT CONSTRAINT [FK_LabelBrandTS_brand_id] FOREIGN KEY REFERENCES Products.Brand(brand_id) NOT NULL,
	ts_id INT CONSTRAINT [FK_LabelBrandTS_ts_id] FOREIGN KEY REFERENCES Products.TechSize(ts_id) NOT NULL,
	rmt_id INT CONSTRAINT [FK_LabelBrandTS_rmt_id] FOREIGN KEY REFERENCES Material.RawMaterialType(rmt_id) NOT NULL,
	CONSTRAINT [PK_LabelBrandTS] PRIMARY KEY CLUSTERED (brand_id, ts_id) 
)
