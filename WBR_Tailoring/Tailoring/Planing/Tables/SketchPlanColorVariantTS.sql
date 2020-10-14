CREATE TABLE [Planing].[SketchPlanColorVariantTS] (
    [spcvts_id]       INT           IDENTITY (1, 1) NOT NULL,
    [spcv_id]         INT           NOT NULL,
    [ts_id]           INT           NOT NULL,
    [cnt]             SMALLINT      NOT NULL,
    [dt]              DATETIME2 (0) NOT NULL,
    [employee_id]     INT           NOT NULL,
    [cut_cnt_for_job] SMALLINT      NULL,
    CONSTRAINT [PK_SketchPlanColorVariantTS] PRIMARY KEY CLUSTERED ([spcvts_id] ASC),
    CONSTRAINT [FK_SketchPlanColorVariantTS_spcv_id] FOREIGN KEY ([spcv_id]) REFERENCES [Planing].[SketchPlanColorVariant] ([spcv_id]),
    CONSTRAINT [FK_SketchPlanColorVariantTS_ts_id] FOREIGN KEY ([ts_id]) REFERENCES [Products].[TechSize] ([ts_id])
);



GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_SketchPlanColorVariantTS] ON Planing.SketchPlanColorVariantTS(spcv_id, ts_id) ON [Indexes]
GO
GRANT SELECT
    ON OBJECT::[Planing].[SketchPlanColorVariantTS] TO [wildberries\olap-orr]
    AS [dbo];

