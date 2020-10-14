CREATE TABLE [Manufactory].[LayoutAddedSketch]
(
	las_id                INT IDENTITY(1, 1) CONSTRAINT [PK_LayoutAddedSketch] PRIMARY KEY CLUSTERED NOT NULL,
	layout_id             INT CONSTRAINT [FK_LayoutAddedSketch_layout_id] FOREIGN KEY REFERENCES Manufactory.Layout(layout_id) NOT NULL,
	sketch_id             INT CONSTRAINT [FK_LayoutAddedSketch_sketch_id] FOREIGN KEY REFERENCES Products.Sketch(sketch_id) NOT NULL,
	completing_id         INT CONSTRAINT [FK_LayoutAddedSketch_completing_id] FOREIGN KEY REFERENCES Material.Completing(completing_id) NOT NULL,
	completing_number     TINYINT NOT NULL,
	consumption           DECIMAL(9, 3) NOT NULL,
	dt                    DATETIME2(0) NOT NULL,
	employee_id           INT NOT NULL,
	is_deleted            BIT CONSTRAINT [DF_LayoutAddedSketch_is_deleted] DEFAULT(0) NOT NULL
)

GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_LayoutAddedSketch_layout_id_sketch_id_completing_id_completing_number] ON Manufactory.LayoutAddedSketch(layout_id, sketch_id, completing_id, completing_number) 
ON [Indexes]
