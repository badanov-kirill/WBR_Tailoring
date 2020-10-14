CREATE TABLE [Manufactory].[TaskSample]
(
	task_sample_id             INT IDENTITY(1, 1) CONSTRAINT [PK_TaskSample] PRIMARY KEY CLUSTERED NOT NULL,
	ct_id                      INT CONSTRAINT [FK_TaskSample_ct_id] FOREIGN KEY REFERENCES Material.ClothType(ct_id) NOT NULL,
	qp_id                      TINYINT CONSTRAINT [FK_TaskSample_qp_id] FOREIGN KEY REFERENCES Products.QueuePriority(qp_id) NOT NULL,
	office_id                  INT NOT NULL,
	pattern_employee_id        INT NULL,
	pattern_begin_work_dt      dbo.SECONDSTIME NULL,
	pattern_end_of_work_dt     dbo.SECONDSTIME NULL,
	cut_employee_id            INT NULL,
	cut_begin_work_dt          dbo.SECONDSTIME NULL,
	cut_end_of_work_dt         dbo.SECONDSTIME NULL,
	employee_id                INT NOT NULL,
	dt                         dbo.SECONDSTIME NOT NULL,
	is_deleted                 BIT NOT NULL,
	pattern_comment            VARCHAR(250) NULL,
	cut_comment                VARCHAR(250) NULL,
	create_dt                  dbo.SECONDSTIME NOT NULL,
	problem_dt                 dbo.SECONDSTIME NULL,
	problem_comment            VARCHAR(250) NULL,
	problem_employee_id        INT NULL,
	is_stm                     BIT NULL,
	slicing_dt                 DATETIME2(0) NULL,
	slicing_employee_id        INT NULL,
	proirity_level			   TINYINT CONSTRAINT [DF_TaskSample_priority_level] DEFAULT (0) NOT NULL
)

GO

CREATE NONCLUSTERED INDEX [IX_TaskSample_ct_id_office_id_is_deleted_problem_dt_is_stm]
ON Manufactory.TaskSample (ct_id, office_id, is_deleted, problem_dt, is_stm)
INCLUDE(task_sample_id, qp_id, pattern_employee_id, pattern_begin_work_dt, pattern_end_of_work_dt, cut_employee_id, cut_begin_work_dt)
WHERE is_deleted = 0 AND cut_employee_id IS NULL AND is_stm = 0 AND slicing_dt IS NOT NULL
 ON [Indexes]
 
GO
 
CREATE UNIQUE NONCLUSTERED INDEX [IX_TaskSample_task_sample_id] ON Manufactory.TaskSample (task_sample_id) WHERE slicing_dt IS NULL AND is_deleted = 0 ON 
[Indexes]