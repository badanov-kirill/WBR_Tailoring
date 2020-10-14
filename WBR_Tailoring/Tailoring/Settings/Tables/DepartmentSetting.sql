CREATE TABLE [Settings].[DepartmentSetting]
(
	department_id             INT CONSTRAINT [PK_DepartmentSetting] PRIMARY KEY CLUSTERED NOT NULL,
	department_name           VARCHAR(100) NOT NULL,
	office_id                 INT CONSTRAINT [FK_DepartmentSetting_office_id] FOREIGN KEY REFERENCES Settings.OfficeSetting(office_id) NOT NULL,
	dt                        DATETIME2(0) NOT NULL,
	employee_id               INT NOT NULL,
	parrent_department_id     INT CONSTRAINT [FK_DepartmentSetting_parrent_department_id] FOREIGN KEY REFERENCES Settings.DepartmentSetting(department_id) NULL
)
