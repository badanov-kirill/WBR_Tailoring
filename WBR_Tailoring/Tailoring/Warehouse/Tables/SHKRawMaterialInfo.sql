CREATE TABLE [Warehouse].[SHKRawMaterialInfo] (
    [shkrm_id]            INT      NOT NULL,
    [doc_id]              INT      NOT NULL,
    [doc_type_id]         TINYINT  NOT NULL,
    [suppliercontract_id] INT      NOT NULL,
    [rmt_id]              INT      NOT NULL,
    [art_id]              INT      NOT NULL,
    [color_id]            INT      NOT NULL,
    [su_id]               INT      NOT NULL,
    [frame_width]         SMALLINT NULL,
    [nds]                 TINYINT  NOT NULL,
    [tissue_density]      SMALLINT NULL,
    CONSTRAINT [PK_SHKRawMaterialInfo] PRIMARY KEY CLUSTERED ([shkrm_id] ASC),
    CONSTRAINT [FK_SHKRawMaterialInfo_art_id] FOREIGN KEY ([art_id]) REFERENCES [Material].[Article] ([art_id]),
    CONSTRAINT [FK_SHKRawMaterialInfo_color_id] FOREIGN KEY ([color_id]) REFERENCES [Material].[ClothColor] ([color_id]),
    CONSTRAINT [FK_SHKRawMaterialInfo_doc_type_id] FOREIGN KEY ([doc_type_id]) REFERENCES [Documents].[DocumentType] ([doc_type_id]),
    CONSTRAINT [FK_SHKRawMaterialInfo_nds] FOREIGN KEY ([nds]) REFERENCES [RefBook].[NDS] ([nds]),
    CONSTRAINT [FK_SHKRawMaterialInfo_rmt_id] FOREIGN KEY ([rmt_id]) REFERENCES [Material].[RawMaterialType] ([rmt_id]),
    CONSTRAINT [FK_SHKRawMaterialInfo_shkrm_id] FOREIGN KEY ([shkrm_id]) REFERENCES [Warehouse].[SHKRawMaterial] ([shkrm_id]),
    CONSTRAINT [FK_SHKRawMaterialInfo_su_id] FOREIGN KEY ([su_id]) REFERENCES [RefBook].[SpaceUnit] ([su_id]),
    CONSTRAINT [FK_SHKRawMaterialInfo_supcontr_id] FOREIGN KEY ([suppliercontract_id]) REFERENCES [Suppliers].[SupplierContract] ([suppliercontract_id])
);




GO

CREATE UNIQUE NONCLUSTERED INDEX [UQ_SHKRawMaterialInfo_doc_id_doc_type_id]
    ON Warehouse.SHKRawMaterialInfo(doc_id, doc_type_id, shkrm_id) ON [Indexes];
    
GO
CREATE NONCLUSTERED INDEX [IX_SHKRawMaterialInfo_rmt_id]
    ON Warehouse.SHKRawMaterialInfo(rmt_id)
    INCLUDE(shkrm_id) ON [Indexes];
GO


