CREATE TABLE [History].[SketchPlanColorVariant] (
    [log_id]                 INT                 IDENTITY (1, 1) NOT NULL,
    [spcv_id]                INT                 NOT NULL,
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
    [proc_id]                INT                 NOT NULL,
    [sew_fabricator_id]      INT                 NULL,
    CONSTRAINT [PK_History_SketchPlanColorVariant] PRIMARY KEY CLUSTERED ([log_id] ASC)
);


