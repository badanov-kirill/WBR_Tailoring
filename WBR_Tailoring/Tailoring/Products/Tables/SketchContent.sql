CREATE TABLE [Products].[SketchContent]
(
	sketch_id       INT CONSTRAINT [FK_ScetchContent_sketch_id] FOREIGN KEY REFERENCES Products.Sketch(sketch_id) NOT NULL,
	contents_id     INT CONSTRAINT [FK_ScetchContent_contents_id] FOREIGN KEY REFERENCES Products.Content(contents_id) NOT NULL,
	CONSTRAINT [PK_ScetchContents] PRIMARY KEY CLUSTERED(sketch_id, contents_id)
)