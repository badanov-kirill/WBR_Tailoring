CREATE TABLE [Products].[SketchAddedOption]
(
	sketch_id       INT CONSTRAINT [FK_SketchAddedOption_sketch_id] FOREIGN KEY REFERENCES Products.Sketch(sketch_id) NOT NULL,
	ao_id           INT CONSTRAINT [FK_SketchAddedOption_ao_id] FOREIGN KEY REFERENCES Products.AddedOption(ao_id) NOT NULL,
	employee_id     INT NOT NULL,
	dt              dbo.SECONDSTIME NOT NULL,
	ao_value        DECIMAL(9, 2) NULL,
	si_id           INT CONSTRAINT [FK_SketchAddedOption_si_id] FOREIGN KEY REFERENCES Products.SI (si_id) NULL,
	CONSTRAINT [PK_SketchAddedOption] PRIMARY KEY CLUSTERED(sketch_id, ao_id)
)
