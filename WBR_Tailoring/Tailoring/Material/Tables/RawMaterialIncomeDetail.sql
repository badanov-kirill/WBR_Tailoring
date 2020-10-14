CREATE TABLE [Material].[RawMaterialIncomeDetail] (
    [rmid_id]                    INT                 IDENTITY (1, 1) NOT NULL,
    [doc_id]                     INT                 NOT NULL,
    [doc_type_id]                TINYINT             NOT NULL,
    [shkrm_id]                   INT                 NOT NULL,
    [rmt_id]                     INT                 NOT NULL,
    [art_id]                     INT                 NOT NULL,
    [color_id]                   INT                 NOT NULL,
    [suppliercontract_id]        INT                 NOT NULL,
    [su_id]                      INT                 NOT NULL,
    [okei_id]                    INT                 NOT NULL,
    [qty]                        DECIMAL (9, 2)      NOT NULL,
    [stor_unit_residues_okei_id] INT                 NOT NULL,
    [stor_unit_residues_qty]     DECIMAL (9, 2)      NOT NULL,
    [amount]                     DECIMAL (19, 8)     NOT NULL,
    [nds]                        TINYINT             NOT NULL,
    [dt]                         [dbo].[SECONDSTIME] NOT NULL,
    [employee_id]                INT                 NOT NULL,
    [is_deleted]                 BIT                 NOT NULL,
    [shksu_id]                   INT                 NOT NULL,
    [frame_width]                SMALLINT            NULL,
    [is_defected]                BIT                 NOT NULL,
    CONSTRAINT [PK_RawMaterialIncomeDetail] PRIMARY KEY CLUSTERED ([rmid_id] ASC),
    CONSTRAINT [CH_RawMaterialIncomeDetail_doc_type_id] CHECK ([doc_type_id]=(1)),
    CONSTRAINT [FK_RawMaterialIncomeDetail_art_id] FOREIGN KEY ([art_id]) REFERENCES [Material].[Article] ([art_id]),
    CONSTRAINT [FK_RawMaterialIncomeDetail_color_id] FOREIGN KEY ([color_id]) REFERENCES [Material].[ClothColor] ([color_id]),
    CONSTRAINT [FK_RawMaterialIncomeDetail_doc_id_doc_type_id] FOREIGN KEY ([doc_type_id], [doc_id]) REFERENCES [Documents].[DocumentID] ([doc_type_id], [doc_id]),
    CONSTRAINT [FK_RawMaterialIncomeDetail_okei_id] FOREIGN KEY ([okei_id]) REFERENCES [Qualifiers].[OKEI] ([okei_id]),
    CONSTRAINT [FK_RawMaterialIncomeDetail_rmt_id] FOREIGN KEY ([rmt_id]) REFERENCES [Material].[RawMaterialType] ([rmt_id]),
    CONSTRAINT [FK_RawMaterialIncomeDetail_shkrm_id] FOREIGN KEY ([shkrm_id]) REFERENCES [Warehouse].[SHKRawMaterial] ([shkrm_id]),
    CONSTRAINT [FK_RawMaterialIncomeDetail_shksu_id] FOREIGN KEY ([shksu_id]) REFERENCES [Warehouse].[SHKSpaceUnit] ([shksu_id]),
    CONSTRAINT [FK_RawMaterialIncomeDetail_stor_unit_residues_okei_id] FOREIGN KEY ([stor_unit_residues_okei_id]) REFERENCES [Qualifiers].[OKEI] ([okei_id]),
    CONSTRAINT [FK_RawMaterialIncomeDetail_su_id] FOREIGN KEY ([su_id]) REFERENCES [RefBook].[SpaceUnit] ([su_id]),
    CONSTRAINT [FK_RawMaterialIncomeDetail_suppliercontract_id] FOREIGN KEY ([suppliercontract_id]) REFERENCES [Suppliers].[SupplierContract] ([suppliercontract_id])
);



GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_RawMaterialIncomeDetail_doc_id_doc_type_id_shkrm_id] ON Material.RawMaterialIncomeDetail(doc_id, doc_type_id, shkrm_id) ON 
[Indexes]
GO
GRANT SELECT
    ON OBJECT::[Material].[RawMaterialIncomeDetail] TO [wildberries\olap-orr]
    AS [dbo];

