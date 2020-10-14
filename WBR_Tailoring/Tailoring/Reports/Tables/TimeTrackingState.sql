CREATE TABLE [Reports].[TimeTrackingState]
(
	tt_state_id          TINYINT CONSTRAINT [PK_TimeTrackingState] PRIMARY KEY CLUSTERED NOT NULL,
	tt_state_name     VARCHAR(50) NOT NULL
)
