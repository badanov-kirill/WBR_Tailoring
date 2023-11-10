CREATE TABLE [Settings].[Declarations_TNVED] (
    [id]             INT IDENTITY (1, 1) NOT NULL,
    [declaration_id] INT NOT NULL,
    [tnved_id]       INT NOT NULL,
    CONSTRAINT [PK_declaration_tnved] PRIMARY KEY CLUSTERED ([id] ASC),
    CONSTRAINT [FK_Declarations_TNVED_declaration_id] FOREIGN KEY ([declaration_id]) REFERENCES [Settings].[Declarations] ([declaration_id]),
    CONSTRAINT [FK_Declarations_TNVED_tnved_id] FOREIGN KEY ([tnved_id]) REFERENCES [Products].[TNVED] ([tnved_id])
);

