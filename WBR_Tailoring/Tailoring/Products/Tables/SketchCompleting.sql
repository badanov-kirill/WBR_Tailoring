CREATE TABLE [Products].[SketchCompleting]
(
	sc_id                 INT IDENTITY(1, 1) CONSTRAINT [PK_SketchCompleting] PRIMARY KEY CLUSTERED NOT NULL,
	sketch_id             INT CONSTRAINT [FK_SketchCompleting_sketch_id] FOREIGN KEY REFERENCES Products.Sketch(sketch_id) NOT NULL,
	completing_id         INT CONSTRAINT [FK_SketchCompleting_completing_id] FOREIGN KEY REFERENCES Material.Completing(completing_id) NOT NULL,
	completing_number     TINYINT NOT NULL,
	frame_width           SMALLINT NULL,
	okei_id               INT NOT NULL,
	consumption           DECIMAL(9, 3) NULL,
	comment               VARCHAR(200) NULL,
	is_deleted            BIT NOT NULL,
	dt                    dbo.SECONDSTIME NOT NULL,
	employee_id           INT NOT NULL,
	base_rmt_id           INT CONSTRAINT [FK_SketchCompleting_rmt_id] FOREIGN KEY REFERENCES Material.RawMaterialType(rmt_id) NOT NULL
)

GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_SketchCompleting_sketch_id_completing_id_completing_number] ON Products.SketchCompleting(sketch_id, completing_id, completing_number) 
ON [Indexes]