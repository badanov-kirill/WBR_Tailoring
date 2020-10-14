CREATE TABLE [History].[EmployeeTransferSetting]
(
	log_id INT IDENTITY(1,1) CONSTRAINT [PK_History_EmployeeTransferSetting] PRIMARY KEY CLUSTERED NOT NULL,
	employee_id INT NOT NULL,
	ts_id INT NULL,
	creator_employee_id INT NOT NULL,
	dt dbo.SECONDSTIME NOT NULL,
	is_deleted BIT NOT NULL
)
