CREATE TABLE [Products].[SketchBranchOfficePattern]
(
	sketch_id       INT CONSTRAINT [FK_SketchBranchOfficePattern_so_id] FOREIGN KEY REFERENCES Products.Sketch(sketch_id) NOT NULL,
	office_id       INT NOT NULL,
	employee_id     INT,
	dt              dbo.SECONDSTIME
	CONSTRAINT [PK_SketchBranchOfficePattern] PRIMARY KEY CLUSTERED(sketch_id, office_id)
)