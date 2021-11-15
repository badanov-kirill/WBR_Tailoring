CREATE TABLE [Manufactory].[Sample] (
    [sample_id]              INT                 IDENTITY (1, 1) NOT NULL,
    [sketch_id]              INT                 NOT NULL,
    [task_sample_id]         INT                 NULL,
    [st_id]                  TINYINT             NOT NULL,
    [pattern_perimeter]      INT                 NOT NULL,
    [cut_perimeter]          INT                 NOT NULL,
    [ts_id]                  INT                 NULL,
    [ct_id]                  INT                 NOT NULL,
    [employee_id]            INT                 NOT NULL,
    [dt]                     [dbo].[SECONDSTIME] NOT NULL,
    [is_deleted]             BIT                 NOT NULL,
    [comment]                VARCHAR (250)       NULL,
    [sew_launch_dt]          [dbo].[SECONDSTIME] NULL,
    [sew_launch_employee_id] INT                 NULL,
    CONSTRAINT [PK_Sample] PRIMARY KEY CLUSTERED ([sample_id] ASC),
    CONSTRAINT [FK_Sample_sketch_id] FOREIGN KEY ([sketch_id]) REFERENCES [Products].[Sketch] ([sketch_id]),
    CONSTRAINT [FK_Sample_st_id] FOREIGN KEY ([st_id]) REFERENCES [Manufactory].[SampleType] ([st_id]),
    CONSTRAINT [FK_Sample_task_sample_id] FOREIGN KEY ([task_sample_id]) REFERENCES [Manufactory].[TaskSample] ([task_sample_id]),
    CONSTRAINT [FK_Simple_ct_id] FOREIGN KEY ([ct_id]) REFERENCES [Material].[ClothType] ([ct_id]),
    CONSTRAINT [FK_Simple_ts_id] FOREIGN KEY ([ts_id]) REFERENCES [Products].[TechSize] ([ts_id])
);





GO
CREATE NONCLUSTERED INDEX [IX_Sample_sketch_id] ON Manufactory.[Sample] (sketch_id, is_deleted) ON [Indexes]

GO
CREATE NONCLUSTERED INDEX [IX_Sample_task_sample_id_is_deleted] ON Manufactory.[Sample] (task_sample_id, is_deleted) ON [Indexes]

GO


