CREATE TABLE [Warehouse].[SHKRawMaterialState] (
    [shkrm_id]    INT                 NOT NULL,
    [state_id]    INT                 NOT NULL,
    [dt]          [dbo].[SECONDSTIME] NOT NULL,
    [employee_id] INT                 NOT NULL,
    [rv]          ROWVERSION          NOT NULL,
    CONSTRAINT [PK_SHKRawMaterialState] PRIMARY KEY CLUSTERED ([shkrm_id] ASC),
    CONSTRAINT [FK_SHKRawMaterialState_shkrm_id] FOREIGN KEY ([shkrm_id]) REFERENCES [Warehouse].[SHKRawMaterial] ([shkrm_id]),
    CONSTRAINT [FK_SHKRawMaterialState_state_id] FOREIGN KEY ([state_id]) REFERENCES [Warehouse].[SHKRawMaterialStateDict] ([state_id])
);





GO


