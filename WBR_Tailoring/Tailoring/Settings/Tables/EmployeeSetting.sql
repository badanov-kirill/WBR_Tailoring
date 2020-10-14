CREATE TABLE [Settings].[EmployeeSetting]
(
	employee_id            INT CONSTRAINT [PK_EmployeeSetting] PRIMARY KEY CLUSTERED NOT NULL,
	office_id              INT CONSTRAINT [FK_EmployeeSetting_office_id] FOREIGN KEY REFERENCES Settings.OfficeSetting(office_id) NOT NULL,
	employee_name          VARCHAR(100) NOT NULL,
	dt                     DATETIME2(0) NOT NULL,
	change_employee_id     INT NOT NULL,
	department_id          INT CONSTRAINT [FK_EmployeeSetting_department_id] FOREIGN KEY REFERENCES Settings.DepartmentSetting(department_id) NULL,
	is_work                BIT NOT NULL,
	brigade_id             INT CONSTRAINT [FK_EmployeeSetting_brigade_id] FOREIGN KEY REFERENCES Settings.Brigade(brigade_id) NULL
)
