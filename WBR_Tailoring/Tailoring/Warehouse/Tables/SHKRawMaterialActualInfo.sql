CREATE TABLE [Warehouse].[SHKRawMaterialActualInfo] (
    [shkrm_id]                   INT                 NOT NULL,
    [doc_id]                     INT                 NOT NULL,
    [doc_type_id]                TINYINT             NOT NULL,
    [suppliercontract_id]        INT                 NOT NULL,
    [rmt_id]                     INT                 NOT NULL,
    [art_id]                     INT                 NOT NULL,
    [color_id]                   INT                 NOT NULL,
    [su_id]                      INT                 NOT NULL,
    [okei_id]                    INT                 NOT NULL,
    [qty]                        DECIMAL (9, 3)      NOT NULL,
    [stor_unit_residues_okei_id] INT                 NOT NULL,
    [stor_unit_residues_qty]     DECIMAL (9, 3)      NOT NULL,
    [dt]                         [dbo].[SECONDSTIME] NOT NULL,
    [employee_id]                INT                 NOT NULL,
    [frame_width]                SMALLINT            NULL,
    [is_defected]                BIT                 NOT NULL,
    [is_deleted]                 BIT                 NOT NULL,
    [nds]                        TINYINT             NOT NULL,
    [gross_mass]                 INT                 NOT NULL,
    [rv]                         ROWVERSION          NOT NULL,
    [is_terminal_residues]       BIT                 CONSTRAINT [DF_SHKRawMaterialActualInfo_is_terminal_residues] DEFAULT ((0)) NOT NULL,
    [tissue_density]             SMALLINT            NULL,
    CONSTRAINT [PK_SHKRawMaterialActualInfo] PRIMARY KEY CLUSTERED ([shkrm_id] ASC),
    CONSTRAINT [CH_SHKRawMaterialActualInfo_qty] CHECK ([qty]>(0)),
    CONSTRAINT [CH_SHKRawMaterialActualInfo_stor_unit_res_qty] CHECK ([stor_unit_residues_qty]>(0)),
    CONSTRAINT [FK_SHKRawMaterialActualInfo_art_id] FOREIGN KEY ([art_id]) REFERENCES [Material].[Article] ([art_id]),
    CONSTRAINT [FK_SHKRawMaterialActualInfo_color_id] FOREIGN KEY ([color_id]) REFERENCES [Material].[ClothColor] ([color_id]),
    CONSTRAINT [FK_SHKRawMaterialActualInfo_doc_type_id] FOREIGN KEY ([doc_type_id]) REFERENCES [Documents].[DocumentType] ([doc_type_id]),
    CONSTRAINT [FK_SHKRawMaterialActualInfo_nds] FOREIGN KEY ([nds]) REFERENCES [RefBook].[NDS] ([nds]),
    CONSTRAINT [FK_SHKRawMaterialActualInfo_okei_id] FOREIGN KEY ([okei_id]) REFERENCES [Qualifiers].[OKEI] ([okei_id]),
    CONSTRAINT [FK_SHKRawMaterialActualInfo_rmt_id] FOREIGN KEY ([rmt_id]) REFERENCES [Material].[RawMaterialType] ([rmt_id]),
    CONSTRAINT [FK_SHKRawMaterialActualInfo_shkrm_id] FOREIGN KEY ([shkrm_id]) REFERENCES [Warehouse].[SHKRawMaterial] ([shkrm_id]),
    CONSTRAINT [FK_SHKRawMaterialActualInfo_stor_unit_residues_okei_id] FOREIGN KEY ([stor_unit_residues_okei_id]) REFERENCES [Qualifiers].[OKEI] ([okei_id]),
    CONSTRAINT [FK_SHKRawMaterialActualInfo_su_id] FOREIGN KEY ([su_id]) REFERENCES [RefBook].[SpaceUnit] ([su_id]),
    CONSTRAINT [FK_SHKRawMaterialActualInfo_supcontr_id] FOREIGN KEY ([suppliercontract_id]) REFERENCES [Suppliers].[SupplierContract] ([suppliercontract_id])
);





GO


