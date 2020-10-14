CREATE TABLE [Products].[SketchPatternPerimetr]
(
	spp_id          INT IDENTITY(1, 1) CONSTRAINT [PK_SketchPatternPerimetr] PRIMARY KEY CLUSTERED NOT NULL,
	sketch_id       INT CONSTRAINT [FK_SketchPatternPerimetr_sketch_id] FOREIGN KEY REFERENCES Products.Sketch(sketch_id) NOT NULL,
	ts_id           INT CONSTRAINT [FK_SketchPatternPerimetr_ts_id] FOREIGN KEY REFERENCES Products.TechSize(ts_id) NOT NULL,
	psn_id          INT CONSTRAINT [FK_SketchPatternPerimetr] FOREIGN KEY REFERENCES Products.PatternSizeName(psn_id) NOT NULL,
	perimetr        INT CONSTRAINT [CH_SketchPatternPerimetr_perimetr] CHECK(perimetr > 0) NOT NULL,
	dt              dbo.SECONDSTIME NOT NULL,
	employee_id     INT NOT NULL
)

GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_SketchPatternPerimetr_sketch_id_ts_id] ON Products.SketchPatternPerimetr(sketch_id, ts_id) ON [Indexes]

GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_SketchPatternPerimetr_sketch_id_psn_id] ON Products.SketchPatternPerimetr(sketch_id, psn_id) ON [Indexes]