CREATE TABLE [Documents].[DocumentType]
(
	doc_type_id       TINYINT CONSTRAINT [PK_DocumentsType] PRIMARY KEY CLUSTERED NOT NULL,
	doc_type_name     VARCHAR(100) NOT NULL
)

GO

CREATE UNIQUE NONCLUSTERED INDEX [UQ_DocumentType_doc_type_name] ON Documents.DocumentType(doc_type_name) ON [Indexes]