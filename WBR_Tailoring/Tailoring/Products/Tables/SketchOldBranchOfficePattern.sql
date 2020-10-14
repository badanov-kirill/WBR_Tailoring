CREATE TABLE [Products].[SketchOldBranchOfficePattern]
(
	so_id           INT CONSTRAINT [FK_SketchOldBranchOfficePattern_so_id] FOREIGN KEY REFERENCES Products.SketchOld(so_id) NOT NULL,
	office_id       INT NOT NULL,
	employee_id     INT NOT NULL,
	dt              dbo.SECONDSTIME NOT NULL
	CONSTRAINT [PK_SketchOldBranchOfficePattern] PRIMARY KEY CLUSTERED(so_id, office_id)
)
