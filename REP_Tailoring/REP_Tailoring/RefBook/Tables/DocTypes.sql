CREATE TABLE [RefBook].[DocTypes]
(
	doc_type_id SMALLINT IDENTITY(1,1) CONSTRAINT [PK_DocTypes] PRIMARY KEY CLUSTERED NOT NULL,
	doc_type_name VARCHAR(50) NOT NULL
)

GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_DocTypes_doc_type_name] ON RefBook.DocTypes(doc_type_name) INCLUDE(doc_type_id) ON [Indexes]