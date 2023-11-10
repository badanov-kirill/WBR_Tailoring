CREATE TABLE [Settings].[Declaration_types] (
    [declaration_type_id] INT          IDENTITY (1, 1) NOT NULL,
    [declaration_type]    VARCHAR (50) NOT NULL,
    CONSTRAINT [PK_document_type] PRIMARY KEY CLUSTERED ([declaration_type_id] ASC)
);

