CREATE TABLE [History].[TimeTracking]
(
	log_id INT IDENTITY(1, 1) CONSTRAINT [PK_HistoryTimeTracking] PRIMARY KEY CLUSTERED NOT NULL,
	tt_id INT NOT NULL,
	dt DATETIME2(0) NOT NULL,
	employee_id INT NOT NULL,
	tt_state_id TINYINT NOT NULL
)
