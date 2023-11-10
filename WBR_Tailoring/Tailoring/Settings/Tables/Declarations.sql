CREATE TABLE [Settings].[Declarations] (
    [declaration_id]      INT          IDENTITY (1, 1) NOT NULL,
    [declaration_number]  VARCHAR (50) NOT NULL,
    [start_date]          DATE         NOT NULL,
    [end_date]            DATE         NOT NULL,
    [declaration_type_id] INT          NULL,
    CONSTRAINT [PK_declaration] PRIMARY KEY CLUSTERED ([declaration_id] ASC),
    CONSTRAINT [FK_Declaration_types] FOREIGN KEY ([declaration_type_id]) REFERENCES [Settings].[Declaration_types] ([declaration_type_id])
);

