CREATE TABLE [Warehouse].[CancellationShkRM] (
    [csrm_id]                    INT                 IDENTITY (1, 1) NOT NULL,
    [cancellation_id]            INT                 NOT NULL,
    [shkrm_id]                   INT                 NOT NULL,
    [doc_id]                     INT                 NOT NULL,
    [doc_type_id]                TINYINT             NOT NULL,
    [rmt_id]                     INT                 NOT NULL,
    [art_id]                     INT                 NOT NULL,
    [color_id]                   INT                 NOT NULL,
    [su_id]                      INT                 NOT NULL,
    [suppliercontract_id]        INT                 NOT NULL,
    [okei_id]                    INT                 NOT NULL,
    [qty]                        DECIMAL (9, 3)      NOT NULL,
    [stor_unit_residues_okei_id] INT                 NOT NULL,
    [stor_unit_residues_qty]     DECIMAL (9, 3)      NOT NULL,
    [nds]                        TINYINT             NOT NULL,
    [dt]                         [dbo].[SECONDSTIME] NOT NULL,
    [employee_id]                INT                 NOT NULL,
    [is_deleted]                 BIT                 NOT NULL,
    [frame_width]                SMALLINT            NULL,
    [is_defected]                BIT                 NOT NULL,
    CONSTRAINT [PK_CancellationShkRM] PRIMARY KEY CLUSTERED ([csrm_id] ASC),
    CONSTRAINT [FK_CancellationShkRM_art_id] FOREIGN KEY ([art_id]) REFERENCES [Material].[Article] ([art_id]),
    CONSTRAINT [FK_CancellationShkRM_cancellation_id] FOREIGN KEY ([cancellation_id]) REFERENCES [Warehouse].[Cancellation] ([cancellation_id]),
    CONSTRAINT [FK_CancellationShkRM_color_id] FOREIGN KEY ([color_id]) REFERENCES [Material].[ClothColor] ([color_id]),
    CONSTRAINT [FK_CancellationShkRM_doc_type_id] FOREIGN KEY ([doc_type_id]) REFERENCES [Documents].[DocumentType] ([doc_type_id]),
    CONSTRAINT [FK_CancellationShkRM_okei_id] FOREIGN KEY ([okei_id]) REFERENCES [Qualifiers].[OKEI] ([okei_id]),
    CONSTRAINT [FK_CancellationShkRM_rmt_id] FOREIGN KEY ([rmt_id]) REFERENCES [Material].[RawMaterialType] ([rmt_id]),
    CONSTRAINT [FK_CancellationShkRM_shkrm_id] FOREIGN KEY ([shkrm_id]) REFERENCES [Warehouse].[SHKRawMaterial] ([shkrm_id]),
    CONSTRAINT [FK_CancellationShkRM_stor_unit_residues_okei_id] FOREIGN KEY ([stor_unit_residues_okei_id]) REFERENCES [Qualifiers].[OKEI] ([okei_id]),
    CONSTRAINT [FK_CancellationShkRM_su_id] FOREIGN KEY ([su_id]) REFERENCES [RefBook].[SpaceUnit] ([su_id]),
    CONSTRAINT [FK_CancellationShkRM_suppliercontract_id] FOREIGN KEY ([suppliercontract_id]) REFERENCES [Suppliers].[SupplierContract] ([suppliercontract_id])
);



GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_CancellationShkRM_cancellation_id_shkrm_id] ON [Warehouse].[CancellationShkRM](cancellation_id, shkrm_id) ON [Indexes]

GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_CancellationShkRM_shkrm_id] ON [Warehouse].[CancellationShkRM](shkrm_id) ON [Indexes]
GO
GRANT SELECT
    ON OBJECT::[Warehouse].[CancellationShkRM] TO [wildberries\olap-orr]
    AS [dbo];

