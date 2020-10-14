CREATE TABLE [Manufactory].[SPCV_TechnologicalSequence] (
    [sts_id]          INT            IDENTITY (1, 1) NOT NULL,
    [spcv_id]         INT            NOT NULL,
    [operation_range] SMALLINT       NOT NULL,
    [ct_id]           INT            NOT NULL,
    [ta_id]           INT            NOT NULL,
    [element_id]      INT            NOT NULL,
    [equipment_id]    INT            NOT NULL,
    [dr_id]           TINYINT        NOT NULL,
    [dc_id]           TINYINT        NOT NULL,
    [operation_value] DECIMAL (9, 3) NOT NULL,
    [discharge_id]    TINYINT        NOT NULL,
    [rotaiting]       DECIMAL (9, 5) NOT NULL,
    [dc_coefficient]  DECIMAL (9, 5) NOT NULL,
    [employee_id]     INT            NOT NULL,
    [dt]              DATETIME2 (0)  NOT NULL,
    [operation_time]  AS             (([operation_value]*[rotaiting])*[dc_coefficient]),
    [comment_id]      INT            NOT NULL,
    CONSTRAINT [PK_SPCV_TechnologicalSequence] PRIMARY KEY CLUSTERED ([sts_id] ASC),
    CONSTRAINT [FK_SPCV_TechnologicalSequence_comment_id] FOREIGN KEY ([comment_id]) REFERENCES [Technology].[CommentDict] ([comment_id]),
    CONSTRAINT [FK_SPCV_TechnologicalSequence_ct_id] FOREIGN KEY ([ct_id]) REFERENCES [Material].[ClothType] ([ct_id]),
    CONSTRAINT [FK_SPCV_TechnologicalSequence_dc_id] FOREIGN KEY ([dc_id]) REFERENCES [Technology].[DrawingComplexity] ([dc_id]),
    CONSTRAINT [FK_SPCV_TechnologicalSequence_discharge_id] FOREIGN KEY ([discharge_id]) REFERENCES [Technology].[Discharge] ([discharge_id]),
    CONSTRAINT [FK_SPCV_TechnologicalSequence_dr_id] FOREIGN KEY ([dr_id]) REFERENCES [Technology].[DifficultyRebuffing] ([dr_id]),
    CONSTRAINT [FK_SPCV_TechnologicalSequence_element_id] FOREIGN KEY ([element_id]) REFERENCES [Technology].[Element] ([element_id]),
    CONSTRAINT [FK_SPCV_TechnologicalSequence_equipment_id] FOREIGN KEY ([equipment_id]) REFERENCES [Technology].[Equipment] ([equipment_id]),
    CONSTRAINT [FK_SPCV_TechnologicalSequence_spcv_id] FOREIGN KEY ([spcv_id]) REFERENCES [Planing].[SketchPlanColorVariant] ([spcv_id]),
    CONSTRAINT [FK_SPCV_TechnologicalSequence_ta_id] FOREIGN KEY ([ta_id]) REFERENCES [Technology].[TechAction] ([ta_id])
);



GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_SPCV_TechnologicalSequence_sketch_id_operation_range] ON Manufactory.SPCV_TechnologicalSequence(spcv_id, operation_range) 
ON [Indexes]

GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_SPCV_TechnologicalSequence_sketch_id_ta_id_element_id_equipment_id_operation_value_comment_id]
    ON [Manufactory].[SPCV_TechnologicalSequence]([spcv_id] ASC, [ta_id] ASC, [element_id] ASC, [equipment_id] ASC, [comment_id] ASC)
    ON [Indexes];

   

GO
CREATE NONCLUSTERED INDEX [UQ_SPCV_TechnologicalSequence_ta_id] ON Manufactory.SPCV_TechnologicalSequence (ta_id) INCLUDE (sts_id,element_id) ON [Indexes]  

GO
CREATE NONCLUSTERED INDEX [IX_SPCV_TechnologicalSequenceJob_job_employee_id_close_dt]
ON Manufactory.SPCV_TechnologicalSequenceJob (job_employee_id, close_dt)
INCLUDE(sts_id, plan_cnt)  ON [Indexes]  
