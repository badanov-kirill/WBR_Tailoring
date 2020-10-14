CREATE TABLE [Warehouse].[Workshop] (
    [workshop_id]     INT                 IDENTITY (1, 1) NOT NULL,
    [workshop_name]   VARCHAR (50)        NOT NULL,
    [place_id]        INT                 NOT NULL,
    [dt]              [dbo].[SECONDSTIME] NOT NULL,
    [employee_id]     INT                 NULL,
    [return_place_id] INT                 NOT NULL,
    CONSTRAINT [PK_Workshop] PRIMARY KEY CLUSTERED ([workshop_id] ASC),
    CONSTRAINT [FK_Workshop_place_id] FOREIGN KEY ([place_id]) REFERENCES [Warehouse].[StoragePlace] ([place_id]),
    CONSTRAINT [FK_Workshop_return_place_id] FOREIGN KEY ([return_place_id]) REFERENCES [Warehouse].[StoragePlace] ([place_id])
);



GO
GRANT SELECT
    ON OBJECT::[Warehouse].[Workshop] TO [wildberries\olap-orr]
    AS [dbo];

