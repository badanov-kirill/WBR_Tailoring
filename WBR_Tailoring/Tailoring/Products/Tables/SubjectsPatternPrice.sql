CREATE TABLE [Products].[SubjectsPatternPrice]
(
	subject_id     INT CONSTRAINT [FK_SubjectsPatternPrice_subject_id] FOREIGN KEY REFERENCES Products.[Subject](subject_id) NOT NULL,
	price          DECIMAL(15, 2) NOT NULL,
	CONSTRAINT [PK_SubjectsPatternPrice] PRIMARY KEY CLUSTERED(subject_id)
)
