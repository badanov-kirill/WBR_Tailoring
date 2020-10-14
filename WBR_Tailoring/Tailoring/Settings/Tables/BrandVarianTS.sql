CREATE TABLE [Settings].[BrandVarianTS]
(
	bvts_id         INT IDENTITY(1, 1) CONSTRAINT [PK_BrandVarianTS] PRIMARY KEY CLUSTERED NOT NULL,
	brand_id        INT CONSTRAINT [FK_BrandVarianTS_brand_id] FOREIGN KEY REFERENCES Products.Brand(brand_id) NOT NULL,
	max_ts_name     VARCHAR(15),
	min_ts_name     VARCHAR(15),
	cnt_ts          SMALLINT NOT NULL,
	dt              DATETIME2(0) NOT NULL,
	employee_id     INT NOT NULL
)

GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_BrandVarianTS_brand_id_max_ts_name_min_ts_name] ON [Settings].[BrandVarianTS](brand_id, max_ts_name, min_ts_name) ON 
[Indexes]
