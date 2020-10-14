CREATE TABLE [Settings].[TransferSettingOfiice]
(
	tso_id        INT IDENTITY(1, 1) CONSTRAINT [PK_TransferSettingOfiice] PRIMARY KEY CLUSTERED NOT NULL,
	ts_id         INT CONSTRAINT [FK_TransferSettingOfiice_ts_id] FOREIGN KEY REFERENCES Settings.TransferSetting(ts_id) NOT NULL,
	office_id     INT CONSTRAINT [FK_TransferSettingOfiice_office_id] FOREIGN KEY REFERENCES Settings.OfficeSetting(office_id) NOT NULL
)
