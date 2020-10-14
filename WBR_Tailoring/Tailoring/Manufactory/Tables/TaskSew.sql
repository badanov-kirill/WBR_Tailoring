CREATE TABLE [Manufactory].[TaskSew] (
    [ts_id]                INT                 IDENTITY (1, 1) NOT NULL,
    [ct_id]                INT                 NOT NULL,
    [qp_id]                TINYINT             NOT NULL,
    [office_id]            INT                 NOT NULL,
    [employee_id]          INT                 NOT NULL,
    [dt]                   [dbo].[SECONDSTIME] NOT NULL,
    [is_deleted]           BIT                 NOT NULL,
    [create_dt]            [dbo].[SECONDSTIME] NOT NULL,
    [priority_employee_id] INT                 NULL,
    [sew_employee_id]      INT                 NULL,
    [sew_begin_work_dt]    [dbo].[SECONDSTIME] NULL,
    [sew_end_work_dt]      [dbo].[SECONDSTIME] NULL,
    [comment]              VARCHAR (500)       NULL,
    [estimated_time]       SMALLINT            NULL,
    CONSTRAINT [PK_TaskSew] PRIMARY KEY CLUSTERED ([ts_id] ASC),
    CONSTRAINT [FK_TaskSew_ct_id] FOREIGN KEY ([ct_id]) REFERENCES [Material].[ClothType] ([ct_id]),
    CONSTRAINT [FK_TaskSew_qp_id] FOREIGN KEY ([qp_id]) REFERENCES [Products].[QueuePriority] ([qp_id])
);



GO
CREATE NONCLUSTERED INDEX [IX_TaskSew_is_deleted_sew_employee_id_sew_end_work_dt]
ON Manufactory.TaskSew (is_deleted, sew_employee_id, sew_end_work_dt)
WHERE is_deleted = 0 AND sew_employee_id IS NULL ON [Indexes]
GO
GRANT SELECT
    ON OBJECT::[Manufactory].[TaskSew] TO [wildberries\olap-orr]
    AS [dbo];

