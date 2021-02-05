CREATE TABLE [WBApi].[SubjectNomenclatureFields]
(
	subject_id       INT CONSTRAINT [FK_SubjectNomenclatureFields_subject_id] FOREIGN KEY REFERENCES Products.[Subject](subject_id) NOT NULL,
	fields_id        INT CONSTRAINT [FK_SubjectNomenclatureFields_fields_id] FOREIGN KEY REFERENCES WBApi.Fields(fields_id) NOT NULL,
	is_available     BIT NOT NULL,
	is_required      BIT NOT NULL,
	dt               DATETIME2(0) NOT NULL
)
