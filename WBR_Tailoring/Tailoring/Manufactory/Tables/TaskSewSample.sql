CREATE TABLE [Manufactory].[TaskSewSample] (
    [tss_id]                    INT                 IDENTITY (1, 1) NOT NULL,
    [ts_id]                     INT                 NOT NULL,
    [sample_id]                 INT                 NOT NULL,
    [stream_time]               SMALLINT            NULL,
    [dt]                        [dbo].[SECONDSTIME] NOT NULL,
    [employee_id]               INT                 NOT NULL,
    [has_problem_dt]            [dbo].[SECONDSTIME] NULL,
    [close_problem_employee_id] INT                 NULL,
    [close_problem_dt]          [dbo].[SECONDSTIME] NULL,
    [close_employee_id]         INT                 NULL,
    [close_dt]                  [dbo].[SECONDSTIME] NULL,
    [is_mixed]                  BIT                 NULL,
    CONSTRAINT [PK_TaskSewSample] PRIMARY KEY CLUSTERED ([tss_id] ASC),
    CONSTRAINT [FK_TaskSewSample_sample_id] FOREIGN KEY ([sample_id]) REFERENCES [Manufactory].[Sample] ([sample_id]),
    CONSTRAINT [FK_TaskSewSample_ts_id] FOREIGN KEY ([ts_id]) REFERENCES [Manufactory].[TaskSew] ([ts_id])
);





GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_TaskSewSample_ts_id_sample_id] ON Manufactory.TaskSewSample(ts_id,sample_id) ON [Indexes]

GO
CREATE NONCLUSTERED INDEX [IX__TaskSewSample_]
ON [Manufactory].[TaskSewSample] (sample_id)
INCLUDE (ts_id,has_problem_dt,close_problem_dt,close_dt) ON [Indexes]
GO


