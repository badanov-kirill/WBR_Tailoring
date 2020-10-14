CREATE TABLE [Warehouse].[SHKRawMaterialStateDict] (
    [state_id]    INT                 NOT NULL,
    [state_name]  VARCHAR (50)        NOT NULL,
    [state_descr] VARCHAR (500)       NULL,
    [dt]          [dbo].[SECONDSTIME] NOT NULL,
    [employee_id] INT                 NOT NULL,
    CONSTRAINT [PK_SHKRawMaterialStateDict] PRIMARY KEY CLUSTERED ([state_id] ASC)
);



GO 

CREATE UNIQUE NONCLUSTERED INDEX [UQ_SHKRawMaterialStateDict_state_name] ON Warehouse.SHKRawMaterialStateDict(state_name) ON [Indexes]

GO
GRANT SELECT
    ON OBJECT::[Warehouse].[SHKRawMaterialStateDict] TO [wildberries\olap-orr]
    AS [dbo];

