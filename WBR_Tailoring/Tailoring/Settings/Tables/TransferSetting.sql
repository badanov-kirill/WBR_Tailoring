CREATE TABLE [Settings].[TransferSetting]
(
	ts_id            INT IDENTITY(1, 1) CONSTRAINT [PK_TransferSetting] PRIMARY KEY CLUSTERED NOT NULL,
	setting_name     VARCHAR(100) NOT NULL,
	office_id        INT CONSTRAINT [FK_TransferSetting_office_id] FOREIGN KEY REFERENCES Settings.OfficeSetting(office_id) NOT NULL,
	is_deleted       BIT NOT NULL,
	employee_id      INT NOT NULL,
	dt               dbo.SECONDSTIME NOT NULL
)
