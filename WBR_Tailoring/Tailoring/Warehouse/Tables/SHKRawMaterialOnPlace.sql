CREATE TABLE [Warehouse].[SHKRawMaterialOnPlace] (
    [shkrm_id]    INT                 NOT NULL,
    [place_id]    INT                 NOT NULL,
    [dt]          [dbo].[SECONDSTIME] NOT NULL,
    [employee_id] INT                 NOT NULL,
    [rv]          ROWVERSION          NOT NULL,
    CONSTRAINT [PK_SHKRawMaterialOnPlace] PRIMARY KEY CLUSTERED ([shkrm_id] ASC),
    CONSTRAINT [FK_SHKRawMaterialOnPlace_place_id] FOREIGN KEY ([place_id]) REFERENCES [Warehouse].[StoragePlace] ([place_id]),
    CONSTRAINT [FK_SHKRawMaterialOnPlace_shkrm_id] FOREIGN KEY ([shkrm_id]) REFERENCES [Warehouse].[SHKRawMaterial] ([shkrm_id])
);


GO
GRANT SELECT
    ON OBJECT::[Warehouse].[SHKRawMaterialOnPlace] TO [wildberries\olap-orr]
    AS [dbo];

