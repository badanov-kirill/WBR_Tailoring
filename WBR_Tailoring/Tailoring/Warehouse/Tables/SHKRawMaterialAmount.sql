CREATE TABLE [Warehouse].[SHKRawMaterialAmount] (
    [shkrm_id]                   INT             NOT NULL,
    [stor_unit_residues_okei_id] INT             NOT NULL,
    [stor_unit_residues_qty]     DECIMAL (9, 3)  NOT NULL,
    [amount]                     DECIMAL (19, 8) NOT NULL,
    [gross_mass]                 INT             NOT NULL,
    [final_dt]                   DATETIME2 (0)   NULL,
    CONSTRAINT [PK_SHKRawMaterialAmount] PRIMARY KEY CLUSTERED ([shkrm_id] ASC),
    CONSTRAINT [CH_SHKRawMaterialAmount_amount] CHECK ([amount]>=(0)),
    CONSTRAINT [CH_SHKRawMaterialAmount_stor_unit_res_qty] CHECK ([stor_unit_residues_qty]>(0)),
    CONSTRAINT [FK_SHKRawMaterialAmount_shkrm_id] FOREIGN KEY ([shkrm_id]) REFERENCES [Warehouse].[SHKRawMaterial] ([shkrm_id]),
    CONSTRAINT [FK_SHKRawMaterialAmount_stor_unit_residues_okei_id] FOREIGN KEY ([stor_unit_residues_okei_id]) REFERENCES [Qualifiers].[OKEI] ([okei_id])
);





GO
CREATE NONCLUSTERED INDEX [IX_SHKRawMaterialAmount_amount_final_dt]
    ON Warehouse.SHKRawMaterialAmount(amount, final_dt)
    INCLUDE(shkrm_id, stor_unit_residues_qty) ON [Indexes];
GO


