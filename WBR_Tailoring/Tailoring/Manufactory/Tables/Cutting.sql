CREATE TABLE [Manufactory].[Cutting] (
    [cutting_id]          INT                 IDENTITY (1, 1) NOT NULL,
    [office_id]           INT                 NOT NULL,
    [pants_id]            INT                 NOT NULL,
    [pt_id]               TINYINT             NOT NULL,
    [create_employee_id]  INT                 NOT NULL,
    [create_dt]           [dbo].[SECONDSTIME] NOT NULL,
    [employee_id]         INT                 NOT NULL,
    [dt]                  [dbo].[SECONDSTIME] NOT NULL,
    [plan_count]          SMALLINT            NOT NULL,
    [perimeter]           INT                 NOT NULL,
    [plan_year]           SMALLINT            NULL,
    [plan_month]          TINYINT             NULL,
    [planing_employee_id] INT                 NULL,
    [planing_dt]          [dbo].[SECONDSTIME] NULL,
    [closing_employee_id] INT                 NULL,
    [closing_dt]          [dbo].[SECONDSTIME] NULL,
    [plan_start_dt]       DATE                NOT NULL,
    [spcvts_id]           INT                 NULL,
    [cutting_tariff]      DECIMAL (9, 6)      NOT NULL,
    CONSTRAINT [PK_Cutting] PRIMARY KEY CLUSTERED ([cutting_id] ASC),
    CONSTRAINT [FK_Cutting_chrt_id] FOREIGN KEY ([pants_id]) REFERENCES [Products].[ProdArticleNomenclatureTechSize] ([pants_id]),
    CONSTRAINT [FK_Cutting_office_id] FOREIGN KEY ([office_id]) REFERENCES [Settings].[OfficeSetting] ([office_id]),
    CONSTRAINT [FK_Cutting_pt_id] FOREIGN KEY ([pt_id]) REFERENCES [Products].[ProductType] ([pt_id]),
    CONSTRAINT [FK_Cutting_spcvts_id] FOREIGN KEY ([spcvts_id]) REFERENCES [Planing].[SketchPlanColorVariantTS] ([spcvts_id])
);



GO
CREATE NONCLUSTERED INDEX [IX_Cutting_office_id_plan_year_plan_month_chrt_id] ON Manufactory.Cutting(office_id, plan_year, plan_month, pants_id) ON 
[Indexes]

GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_Cutting_spcvts_id] ON Manufactory.Cutting(spcvts_id) WHERE spcvts_id IS NOT NULL ON [Indexes]
GO
GRANT SELECT
    ON OBJECT::[Manufactory].[Cutting] TO [wildberries\olap-orr]
    AS [dbo];

