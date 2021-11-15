CREATE TABLE [Warehouse].[MaterialInProduction] (
    [mip_id]               INT                 IDENTITY (1, 1) NOT NULL,
    [dt]                   [dbo].[SECONDSTIME] NOT NULL,
    [employee_id]          INT                 NOT NULL,
    [create_dt]            [dbo].[SECONDSTIME] NOT NULL,
    [create_employee_id]   INT                 NOT NULL,
    [complite_dt]          [dbo].[SECONDSTIME] NULL,
    [complite_employee_id] INT                 NULL,
    [rv]                   ROWVERSION          NOT NULL,
    [workshop_id]          INT                 NULL,
    CONSTRAINT [PK_MaterialInProduction] PRIMARY KEY CLUSTERED ([mip_id] ASC),
    CONSTRAINT [FK_MaterialInProduction_workshop_id] FOREIGN KEY ([workshop_id]) REFERENCES [Warehouse].[Workshop] ([workshop_id])
);





GO


