CREATE TABLE [Reports].[TimeTrackingOtherDayType]
(
	ttod_type_id TINYINT CONSTRAINT [PK_TimeTrackingOtherDayType] PRIMARY KEY CLUSTERED NOT NULL,
	ttod_type_name VARCHAR(50) NOT NULL
)
