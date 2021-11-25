CREATE TABLE [Warehouse].[MaterialInProductionDetailShk] (
    [mipds_id]                   INT            IDENTITY (1, 1) NOT NULL,
    [mip_id]                     INT            NOT NULL,
    [shkrm_id]                   INT            NOT NULL,
    [rmt_id]                     INT            NOT NULL,
    [art_id]                     INT            NOT NULL,
    [okei_id]                    INT            NOT NULL,
    [qty]                        DECIMAL (9, 3) NOT NULL,
    [stor_unit_residues_okei_id] INT            NOT NULL,
    [stor_unit_residues_qty]     DECIMAL (9, 3) NOT NULL,
    [nds]                        TINYINT        NOT NULL,
    [gross_mass]                 INT            NOT NULL,
    [dt]                         DATETIME2 (0)  NOT NULL,
    [employee_id]                INT            NOT NULL,
    [recive_employee_id]         INT            NOT NULL,
    [return_qty]                 DECIMAL (9, 3) NULL,
    [return_dt]                  DATETIME2 (0)  NULL,
    [return_employee_id]         INT            NULL,
    [return_recive_employee_id]  INT            NULL,
    [doc_id]                     INT            NULL,
    [doc_type_id]                TINYINT        NULL,
    CONSTRAINT [PK_MaterialInProductionDetailShk] PRIMARY KEY CLUSTERED ([mipds_id] ASC),
    CONSTRAINT [CH_MaterialInProductionDetailShk_qty] CHECK ([qty]>(0)),
    CONSTRAINT [CH_MaterialInProductionDetailShk_su_qty] CHECK ([stor_unit_residues_qty]>(0)),
    CONSTRAINT [FK_MaterialInProductionDetailShk_art_id] FOREIGN KEY ([art_id]) REFERENCES [Material].[Article] ([art_id]),
    CONSTRAINT [FK_MaterialInProductionDetailShk_doc_type_id] FOREIGN KEY ([doc_type_id]) REFERENCES [Documents].[DocumentType] ([doc_type_id]),
    CONSTRAINT [FK_MaterialInProductionDetailShk_mip_id] FOREIGN KEY ([mip_id]) REFERENCES [Warehouse].[MaterialInProduction] ([mip_id]),
    CONSTRAINT [FK_MaterialInProductionDetailShk_nds] FOREIGN KEY ([nds]) REFERENCES [RefBook].[NDS] ([nds]),
    CONSTRAINT [FK_MaterialInProductionDetailShk_okei_id] FOREIGN KEY ([okei_id]) REFERENCES [Qualifiers].[OKEI] ([okei_id]),
    CONSTRAINT [FK_MaterialInProductionDetailShk_rmt_id] FOREIGN KEY ([rmt_id]) REFERENCES [Material].[RawMaterialType] ([rmt_id]),
    CONSTRAINT [FK_MaterialInProductionDetailShk_shkrm_id] FOREIGN KEY ([shkrm_id]) REFERENCES [Warehouse].[SHKRawMaterial] ([shkrm_id]),
    CONSTRAINT [FK_MaterialInProductionDetailShk_stor_unit_res_okei_id] FOREIGN KEY ([stor_unit_residues_okei_id]) REFERENCES [Qualifiers].[OKEI] ([okei_id])
);





GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_MaterialInProductionDetailShk_shkrm_id] ON Warehouse.MaterialInProductionDetailShk(shkrm_id) WHERE return_dt IS NULL ON 
[Indexes]

GO


