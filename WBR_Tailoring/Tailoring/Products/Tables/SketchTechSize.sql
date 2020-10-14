CREATE TABLE [Products].[SketchTechSize]
(
	sketch_id     INT CONSTRAINT [FK_SketchTechSize_sketch_id] FOREIGN KEY REFERENCES Products.Sketch(sketch_id) NOT NULL,
	ts_id         INT CONSTRAINT [FK_SketchTechSize_ts_id] FOREIGN KEY REFERENCES Products.TechSize(ts_id) NOT NULL,
	CONSTRAINT [PK_SketchTechSize] PRIMARY KEY CLUSTERED(sketch_id, ts_id)
)