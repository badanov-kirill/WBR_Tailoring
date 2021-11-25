CREATE TABLE [Manufactory].[Operation] (
    [operation_id]          SMALLINT            IDENTITY (1, 1) NOT NULL,
    [operation_name]        VARCHAR (50)        NOT NULL,
    [operation_description] VARCHAR (300)       NOT NULL,
    [employee_id]           INT                 NOT NULL,
    [dt]                    [dbo].[SECONDSTIME] NOT NULL,
    CONSTRAINT [PK_Operation] PRIMARY KEY CLUSTERED ([operation_id] ASC)
);






GO


