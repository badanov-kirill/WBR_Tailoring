CREATE TABLE [Material].[RawMaterialType] (
    [rmt_id]                     INT                 IDENTITY (1, 1) NOT NULL,
    [rmt_pid]                    INT                 NULL,
    [rmt_name]                   VARCHAR (100)       NOT NULL,
    [employee_id]                INT                 NOT NULL,
    [dt]                         [dbo].[SECONDSTIME] NOT NULL,
    [stor_unit_residues_okei_id] INT                 NULL,
    [rmt_astra_id]               INT                 NULL,
    [rv]                         ROWVERSION          NOT NULL,
    CONSTRAINT [PK_RawMaterialType] PRIMARY KEY CLUSTERED ([rmt_id] ASC),
    CONSTRAINT [FK_RawMaterialType_rmt_pid] FOREIGN KEY ([rmt_pid]) REFERENCES [Material].[RawMaterialType] ([rmt_id]),
    CONSTRAINT [FK_RawMaterialType_stor_unit_residues_okei_id] FOREIGN KEY ([stor_unit_residues_okei_id]) REFERENCES [Qualifiers].[OKEI] ([okei_id])
);





GO

CREATE UNIQUE NONCLUSTERED INDEX [UQ_RawMaterialType_rmt_name] ON Material.RawMaterialType(rmt_name, rmt_pid) ON [Indexes]

GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_RawMaterialType_rmt_astra_id] ON Material.RawMaterialType(rmt_astra_id) WHERE rmt_astra_id IS NOT NULL ON [Indexes]
GO


