CREATE TABLE [History].[TimeTrackingOtherDay]
(
	log_id INT IDENTITY(1, 1) CONSTRAINT [PK_HistoryTimeTrackingOtherDay] PRIMARY KEY CLUSTERED NOT NULL,
	ttod_id INT NOT NULL,
	dt DATETIME2(0) NOT NULL,
	employee_id INT NOT NULL,
	tt_state_id TINYINT NOT NULL
)
