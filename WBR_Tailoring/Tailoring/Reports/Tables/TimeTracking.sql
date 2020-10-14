CREATE TABLE [Reports].[TimeTracking]
(
	tt_id INT IDENTITY(1,1) CONSTRAINT [PK_TimeTracking] PRIMARY KEY CLUSTERED NOT NULL,
	tt_dt DATE NOT NULL,
	tt_employee_id INT CONSTRAINT [FK_TimeTracking_tt_employee_id] FOREIGN KEY REFERENCES Settings.EmployeeSetting(employee_id) NOT NULL,
	tt_hour DECIMAL(5,2),
	tt_state_id TINYINT CONSTRAINT [FK_TimeTracking_tt_state] FOREIGN KEY REFERENCES Reports.TimeTrackingState(tt_state_id) NOT NULL,
	dt DATETIME2(0) NULL,
	employee_id INT NULL
)

GO
CREATE NONCLUSTERED INDEX [IX_TimeTrackingtt_employee_id_tt_dt] ON Reports.TimeTracking(tt_employee_id, tt_state_id, tt_dt) INCLUDE(tt_hour) ON [Indexes] 

GO
CREATE NONCLUSTERED INDEX [IX_TimeTrackingtt_tt_dt_employee_id] ON Reports.TimeTracking(tt_dt, tt_state_id, tt_employee_id) INCLUDE(tt_hour) ON [Indexes] 