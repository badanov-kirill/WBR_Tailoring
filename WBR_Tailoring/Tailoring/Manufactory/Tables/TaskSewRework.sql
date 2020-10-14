CREATE TABLE [Manufactory].[TaskSewRework]
(
	tsr_id INT IDENTITY(1,1) CONSTRAINT [PK_TaskSewRework] PRIMARY KEY CLUSTERED NOT NULL,
	ts_id INT CONSTRAINT [FK_TaskSewRework_ts_id] FOREIGN KEY REFERENCES Manufactory.TaskSew(ts_id) NOT NULL,
	create_dt DATETIME2(0) NOT NULL,
	create_employee_id INT NOT NULL,
	sew_employee_id INT NOT NULL,
	close_dt DATETIME2(0) NULL,
	close_employee_id INT NULL,
	new_ts_id INT CONSTRAINT [FK_TaskSewRework_new_ts_id] FOREIGN KEY REFERENCES Manufactory.TaskSew(ts_id) NULL,
	comment VARCHAR(500) NULL
)

GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_TaskSewRework_ts_id] ON Manufactory.TaskSewRework(ts_id) WHERE close_dt IS NULL ON [Indexes]

GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_TaskSewRework_new_ts_id] ON Manufactory.TaskSewRework(new_ts_id) WHERE new_ts_id IS NOT NULL ON [Indexes]