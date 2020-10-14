CREATE TABLE [History].[DocumentType]
(
	log_id            INT IDENTITY(1, 1) CONSTRAINT [PK_History_DocumentType] PRIMARY KEY CLUSTERED NOT NULL,
	doc_type_id       TINYINT NOT NULL,
	doc_type_name     VARCHAR(100) NOT NULL,
	dt                dbo.SECONDSTIME NOT NULL,
	employee_id       INT NOT NULL
)
