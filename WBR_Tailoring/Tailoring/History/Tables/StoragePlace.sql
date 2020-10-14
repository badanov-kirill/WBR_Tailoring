CREATE TABLE [History].[StoragePlace]
(
	log_id                  INT IDENTITY(1, 1) CONSTRAINT [PK_HistoryStoragePlace] PRIMARY KEY CLUSTERED NOT NULL,
	place_id                INT NOT NULL,
	place_name              VARCHAR(50) NOT NULL,
	stage                   INT NULL,
	street                  INT NULL,
	section                 INT NULL,
	rack                    INT NULL,
	field                   INT NULL,
	creator_employee_id     INT NOT NULL,
	create_dt               dbo.SECONDSTIME NOT NULL,
	employee_id             INT NOT NULL,
	dt                      dbo.SECONDSTIME NOT NULL,
	is_deleted              BIT NOT NULL,
	place_type_id           INT NOT NULL,
	zor_id                  INT NOT NULL,
	office_id               INT NULL
)