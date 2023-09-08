CREATE TABLE [Products].[Kind] (
    [kind_id]     INT                 IDENTITY (1, 1) NOT NULL,
    [kind_name]   VARCHAR (25)        NOT NULL,
    [employee_id] INT                 NOT NULL,
    [dt]          [dbo].[SECONDSTIME] NOT NULL,
    [isdeleted]   BIT                 NOT NULL,
    [erp_id]      INT                 NOT NULL,
    [age_id]      INT                 NULL,
    [gender_id]   INT                 NULL,
    [gs1_id]      VARCHAR (20)        NULL,
    [tax]         VARCHAR (40)        NULL,
    CONSTRAINT [PK_Kind] PRIMARY KEY CLUSTERED ([kind_id] ASC),
    CONSTRAINT [FK_Kind_age_id] FOREIGN KEY ([age_id]) REFERENCES [Products].[Age] ([age_id]),
    CONSTRAINT [FK_Kind_gendr_id] FOREIGN KEY ([gender_id]) REFERENCES [Products].[Gender] ([gender_id])
);



GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_Kind_kind_name] ON Products.Kind(kind_name) ON [Indexes]
GO