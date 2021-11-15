CREATE TABLE [History].[SketchStatus] (
    [hss_id]         INT                 IDENTITY (1, 1) NOT NULL,
    [sketch_id]      INT                 NOT NULL,
    [ss_id]          INT                 NOT NULL,
    [employee_id]    INT                 NOT NULL,
    [dt]             [dbo].[SECONDSTIME] NOT NULL,
    [status_comment] VARCHAR (250)       NULL,
    [plan_site_dt]   DATE                NULL,
    CONSTRAINT [PK_History_SketchStatus] PRIMARY KEY CLUSTERED ([hss_id] ASC)
);




GO


