CREATE TABLE [Settings].[BrandVarianTSDetail]
(
	bvtsd_id        INT IDENTITY(1, 1) CONSTRAINT [PK_BrandVarianTSDetail] PRIMARY KEY CLUSTERED NOT NULL,
	bvts_id         INT CONSTRAINT [FK_BrandVarianTSDetail_bcts_id] FOREIGN KEY REFERENCES Settings.BrandVarianTS(bvts_id) NOT NULL,
	ts_id           INT CONSTRAINT [FK_BrandVarianTSDetail_ts_id] FOREIGN KEY REFERENCES Products.TechSize(ts_id) NOT NULL,
	cnt             SMALLINT NOT NULL,
	dt              DATETIME2(0) NOT NULL,
	employee_id     INT NOT NULL
)

GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_BrandVarianTSDetail_bvts_id_ts_id] ON Settings.BrandVarianTSDetail(bvts_id, ts_id) ON [Indexes]