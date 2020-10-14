CREATE TABLE [Planing].[SketchPlanColorVariant] (
    [spcv_id]                INT                 IDENTITY (1, 1) NOT NULL,
    [sp_id]                  INT                 NOT NULL,
    [spcv_name]              VARCHAR (36)        NOT NULL,
    [cvs_id]                 TINYINT             NOT NULL,
    [qty]                    SMALLINT            NOT NULL,
    [employee_id]            INT                 NOT NULL,
    [dt]                     [dbo].[SECONDSTIME] NOT NULL,
    [is_deleted]             BIT                 NOT NULL,
    [comment]                VARCHAR (300)       NULL,
    [pan_id]                 INT                 NULL,
    [corrected_qty]          SMALLINT            NULL,
    [begin_plan_delivery_dt] DATE                NULL,
    [end_plan_delivery_dt]   DATE                NULL,
    [sew_office_id]          INT                 NULL,
    [sew_deadline_dt]        DATE                NULL,
    [cost_plan_year]         SMALLINT            NULL,
    [cost_plan_month]        TINYINT             NULL,
    [issue_dt]               DATETIME2 (0)       NULL,
    [issue_employee_id]      INT                 NULL,
    [pre_cost]               DECIMAL (9, 2)      NULL,
    [set_job_dt]             DATETIME2 (0)       NULL,
    [fist_package_dt]        DATETIME2 (0)       NULL,
    [deadline_package_dt]    DATETIME2 (0)       NULL,
    [master_employee_id]     INT                 NULL,
    CONSTRAINT [PK_SketchPlanColorVariant] PRIMARY KEY CLUSTERED ([spcv_id] ASC),
    CONSTRAINT [FK_SketchPlanColorVariant] FOREIGN KEY ([pan_id]) REFERENCES [Products].[ProdArticleNomenclature] ([pan_id]),
    CONSTRAINT [FK_SketchPlanColorVariant_sew_office_id] FOREIGN KEY ([sew_office_id]) REFERENCES [Settings].[OfficeSetting] ([office_id]),
    CONSTRAINT [FK_SketchPlanColorVariant_sp_id] FOREIGN KEY ([sp_id]) REFERENCES [Planing].[SketchPlan] ([sp_id]),
    CONSTRAINT [FK_SketchPlanColorVariant_spcv_id] FOREIGN KEY ([cvs_id]) REFERENCES [Planing].[ColorVariantStatus] ([cvs_id])
);



GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_SketchPlanColorVariant_sp_id_spcv_name] ON Planing.SketchPlanColorVariant(sp_id, spcv_name) WHERE is_deleted = 0 ON 
[Indexes]

GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_SketchPlanColorVariant_sp_id_pan_id] ON  Planing.SketchPlanColorVariant(sp_id, pan_id) WHERE is_deleted = 0 AND pan_id IS 
NOT NULL ON [Indexes]

GO
CREATE NONCLUSTERED INDEX [IX_SketchPlanColorVariant_cvs_id] ON Planing.SketchPlanColorVariant(cvs_id) INCLUDE(is_deleted, sp_id, qty, sew_office_id) ON 
[Indexes]

GO
CREATE NONCLUSTERED INDEX [IX_SketchPlanColorVariant_fist_package_dt] ON Planing.SketchPlanColorVariant(fist_package_dt) INCLUDE(spcv_id,pan_id) WHERE fist_package_dt IS NOT NULL ON 
[Indexes]
GO
GRANT SELECT
    ON OBJECT::[Planing].[SketchPlanColorVariant] TO [wildberries\olap-orr]
    AS [dbo];

