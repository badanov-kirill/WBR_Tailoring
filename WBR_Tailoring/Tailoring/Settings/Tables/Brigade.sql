CREATE TABLE [Settings].[Brigade]
(
	brigade_id INT IDENTITY(1,1) CONSTRAINT [PK_Brigade] PRIMARY KEY CLUSTERED NOT NULL,
	brigade_name VARCHAR(100) NOT NULL,
	office_id INT CONSTRAINT [FK_Brigade_office_id] FOREIGN KEY REFERENCES Settings.OfficeSetting(office_id) NOT NULL,
	master_employee_id INT CONSTRAINT [FK_Brigade_master_employee_id] FOREIGN KEY REFERENCES Settings.EmployeeSetting(employee_id) NOT NULL,
	employee_id INT NOT NULL,
	dt DATETIME2(0) NOT NULL,
	is_deleted BIT NOT NULL
)

GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_Brigade_brigade_name] ON Settings.Brigade(brigade_name) WHERE is_deleted = 0 ON [Indexes]