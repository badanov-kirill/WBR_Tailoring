CREATE TABLE [Manufactory].[SketchSalaryExecution]
(
	sketch_id INT CONSTRAINT [FK_SketchSalaryExecution_sketch_id] FOREIGN KEY REFERENCES Products.Sketch(sketch_id) NOT NULL,
	CONSTRAINT [PK_SketchSalaryExecution] PRIMARY KEY CLUSTERED(sketch_id)
)
