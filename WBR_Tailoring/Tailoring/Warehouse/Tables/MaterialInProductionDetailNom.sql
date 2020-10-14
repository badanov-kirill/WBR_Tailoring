CREATE TABLE [Warehouse].[MaterialInProductionDetailNom] (
    [mipdn_id]    INT                 IDENTITY (1, 1) NOT NULL,
    [mip_id]      INT                 NOT NULL,
    [pan_id]      INT                 NOT NULL,
    [proportion]  TINYINT             NOT NULL,
    [dt]          [dbo].[SECONDSTIME] NOT NULL,
    [employee_id] INT                 NOT NULL,
    CONSTRAINT [PK_MaterialInProductionDetailNom] PRIMARY KEY CLUSTERED ([mipdn_id] ASC),
    CONSTRAINT [FK_MaterialInProductionDetailNom_mip_id] FOREIGN KEY ([mip_id]) REFERENCES [Warehouse].[MaterialInProduction] ([mip_id]),
    CONSTRAINT [FK_MaterialInProductionDetailNom_pan_id] FOREIGN KEY ([pan_id]) REFERENCES [Products].[ProdArticleNomenclature] ([pan_id])
);



GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_MaterialInProductionDetailNom_mip_id_pan_id] ON Warehouse.MaterialInProductionDetailNom(mip_id, pan_id) ON [Indexes]

GO
GRANT SELECT
    ON OBJECT::[Warehouse].[MaterialInProductionDetailNom] TO [wildberries\olap-orr]
    AS [dbo];

