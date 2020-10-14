CREATE TABLE [Reports].[TimeTrackingOtherDay]
(
	ttod_id INT IDENTITY(1,1) CONSTRAINT [PK_TimeTrackingOtherDay] PRIMARY KEY CLUSTERED NOT NULL,
	ttod_employee_id INT CONSTRAINT [FK_TimeTrackingOtherDay_ttod_employee_id] FOREIGN KEY REFERENCES Settings.EmployeeSetting(employee_id) NOT NULL,
	ttod_start_dt DATE NOT NULL,
	ttod_finish_dt DATE NOT NULL,
	ttod_type_id TINYINT CONSTRAINT [FK_TimeTrackingOtherDay_ttod_type_id] FOREIGN KEY REFERENCES Reports.TimeTrackingOtherDayType(ttod_type_id) NOT NULL,
	tt_state_id TINYINT CONSTRAINT [FK_TimeTrackingOtherDay_ttod_state_id] FOREIGN KEY REFERENCES Reports.TimeTrackingState(tt_state_id) NOT NULL,
	dt DATETIME2(0) NULL,
	employee_id INT NULL
)
