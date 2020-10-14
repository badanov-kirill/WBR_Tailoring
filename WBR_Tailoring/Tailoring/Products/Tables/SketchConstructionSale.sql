CREATE TABLE [Products].[SketchConstructionSale]
(
	sketch_id       INT CONSTRAINT [FK_SketchConstructionSale_sketch_id] FOREIGN KEY REFERENCES Products.Sketch(sketch_id) NOT NULL,
	dt              DATETIME2(0) NOT NULL,
	employee_id     INT NOT NULL,
	CONSTRAINT [PK_SketchConstructionSale] PRIMARY KEY CLUSTERED(sketch_id)
)
