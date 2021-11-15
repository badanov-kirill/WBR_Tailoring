CREATE TABLE [Warehouse].[StoragePlace] (
    [place_id]            INT                 IDENTITY (1, 1) NOT NULL,
    [place_name]          VARCHAR (50)        NOT NULL,
    [stage]               INT                 NULL,
    [street]              INT                 NULL,
    [section]             INT                 NULL,
    [rack]                INT                 NULL,
    [field]               INT                 NULL,
    [creator_employee_id] INT                 NOT NULL,
    [create_dt]           [dbo].[SECONDSTIME] CONSTRAINT [DF_StoragePlace_creator_dt] DEFAULT (getdate()) NOT NULL,
    [employee_id]         INT                 NOT NULL,
    [dt]                  [dbo].[SECONDSTIME] CONSTRAINT [DF_StoragePlace_dt] DEFAULT (getdate()) NOT NULL,
    [is_deleted]          BIT                 NOT NULL,
    [place_type_id]       INT                 NOT NULL,
    [zor_id]              INT                 NOT NULL,
    CONSTRAINT [PK_StoragePlace] PRIMARY KEY CLUSTERED ([place_id] ASC),
    CONSTRAINT [FK_StoragePlace_place_type_id] FOREIGN KEY ([place_type_id]) REFERENCES [Warehouse].[StoragePlaceType] ([place_type_id]),
    CONSTRAINT [FK_StoragePlace_zor_id] FOREIGN KEY ([zor_id]) REFERENCES [Warehouse].[ZoneOfResponse] ([zor_id])
);





GO

CREATE UNIQUE NONCLUSTERED INDEX [UQ_StoragePlace_office_id_place_name] ON Warehouse.StoragePlace(zor_id, place_name) WHERE (is_deleted = 0) ON [Indexes]

GO


