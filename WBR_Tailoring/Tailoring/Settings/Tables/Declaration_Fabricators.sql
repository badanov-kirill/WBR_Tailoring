CREATE TABLE [Settings].[Declaration_Fabricators] (
    [id]             INT IDENTITY (1, 1) NOT NULL,
    [declaration_id] INT NOT NULL,
    [fabricator_id]  INT NULL,
    CONSTRAINT [PK_declaration_Fabricators] PRIMARY KEY CLUSTERED ([id] ASC),
    CONSTRAINT [FK_Declarations_Fabricators_declaration_id] FOREIGN KEY ([declaration_id]) REFERENCES [Settings].[Declarations] ([declaration_id]),
    CONSTRAINT [FK_Declarations_Fabricators_fabricator_id] FOREIGN KEY ([fabricator_id]) REFERENCES [Settings].[Fabricators] ([fabricator_id])
);

