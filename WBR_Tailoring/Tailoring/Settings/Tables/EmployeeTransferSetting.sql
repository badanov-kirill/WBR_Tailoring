CREATE TABLE [Settings].[EmployeeTransferSetting]
(
	employee_id     INT CONSTRAINT [PK_EmployeeTransferSetting] PRIMARY KEY CLUSTERED NOT NULL,
	ts_id           INT CONSTRAINT [FK_EmployeeTransferSetting_ts_id] FOREIGN KEY REFERENCES Settings.TransferSetting(ts_id) NOT NULL,
)
