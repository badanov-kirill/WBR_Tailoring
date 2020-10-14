CREATE TABLE [Warehouse].[ZoneOfResponse] (
    [zor_id]    INT           NOT NULL,
    [zor_name]  VARCHAR (100) NOT NULL,
    [office_id] INT           NULL,
    CONSTRAINT [PK_ZoneOfResponse] PRIMARY KEY CLUSTERED ([zor_id] ASC)
);



GO
GRANT SELECT
    ON OBJECT::[Warehouse].[ZoneOfResponse] TO [wildberries\olap-orr]
    AS [dbo];

