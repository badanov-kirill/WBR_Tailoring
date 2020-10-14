CREATE TABLE [Planing].[EmployeeTable]
(
	work_dt              DATE NOT NULL,
	work_employee_id     INT NOT NULL CONSTRAINT [FK_EmployeeTable_work_employee_id] FOREIGN KEY REFERENCES Settings.EmployeeSetting(employee_id),
	work_time            TINYINT CONSTRAINT [CH_EmployeeTable_work_time] CHECK(work_time >= 0 AND work_time <= 24) NOT NULL,
	employee_id          INT NOT NULL,
	dt                   DATETIME2(0) NOT NULL,
	CONSTRAINT [PK_EmployeeTable] PRIMARY KEY CLUSTERED(work_dt, work_employee_id)
)
