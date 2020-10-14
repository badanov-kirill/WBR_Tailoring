CREATE TABLE [History].[SketchSpecification]
(
	hssp_id                       INT IDENTITY(1, 1) CONSTRAINT [PK_SketchSpecification] PRIMARY KEY CLUSTERED NOT NULL,
	sketch_id                     INT NOT NULL,
	specification_dt              DATETIME2(0) NULL,
	specification_employee_id     INT NULL
)
