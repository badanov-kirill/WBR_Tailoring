CREATE TABLE [Documents].[DocumentID]
(
	doc_id                 INT NOT NULL,
	doc_type_id            TINYINT CONSTRAINT [FK_DocumentID_doc_type_id] FOREIGN KEY REFERENCES Documents.DocumentType(doc_type_id) NOT NULL,
	create_dt              dbo.SECONDSTIME NOT NULL,
	create_employee_id     INT NOT NULL,
	CONSTRAINT [PK_DocumentID] PRIMARY KEY CLUSTERED(doc_type_id, doc_id)
)
