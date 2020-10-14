CREATE TABLE [History].[EmployeeSetting]
(
	log_id                 INT IDENTITY(1, 1) CONSTRAINT [PK_History_EmployeeSetting] PRIMARY KEY CLUSTERED NOT NULL,
	employee_id            INT NOT NULL,
	office_id              INT NOT NULL,
	employee_name          VARCHAR(100) NOT NULL,
	dt                     DATETIME2(0) NOT NULL,
	change_employee_id     INT NOT NULL,
	department_id          INT NULL
)
