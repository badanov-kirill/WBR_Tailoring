CREATE TABLE [Manufactory].[LayoutAddedSketchTS]
(
	lasts_id           INT IDENTITY(1, 1) CONSTRAINT [PK_LayoutAddedSketchTSTS] PRIMARY KEY CLUSTERED NOT NULL,
	las_id             INT CONSTRAINT [FK_LayoutAddedSketchTS_ld_id] FOREIGN KEY REFERENCES Manufactory.LayoutAddedSketch(las_id) NOT NULL,
	ts_id              INT CONSTRAINT [FK_LayoutAddedSketchTS_ts_id] FOREIGN KEY REFERENCES Products.TechSize(ts_id) NOT NULL,
	completing_qty     DECIMAL(9, 3) NOT NULL,
	dt                 DATETIME2(0) NOT NULL,
	employee_id        INT NOT NULL
)

GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_LayoutAddedSketchTS_ld_id_ts_id] ON Manufactory.LayoutAddedSketchTS(las_id, ts_id) ON [Indexes]