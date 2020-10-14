CREATE TABLE [Warehouse].[MaterialInSketchDoc]
(
	misd_id         INT IDENTITY(1, 1) CONSTRAINT [PK_MaterialInSketchDoc] PRIMARY KEY CLUSTERED NOT NULL,
	create_dt       DATETIME2(0) NOT NULL,
	employee_id     INT NOT NULL,
	office_id       INT CONSTRAINT [FK_MaterialInSketchDoc_office_id] FOREIGN KEY REFERENCES Settings.OfficeSetting(office_id) NOT NULL
)
