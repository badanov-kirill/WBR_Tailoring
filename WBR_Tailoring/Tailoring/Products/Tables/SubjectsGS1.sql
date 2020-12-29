CREATE TABLE [Products].[SubjectsGS1]
(
	subject_gs1_id        INT NOT NULL CONSTRAINT [PK_SubjectGS1] PRIMARY KEY CLUSTERED(subject_gs1_id ASC),
	subject_gs1_idnid     INT NOT NULL,
	subject_name          VARCHAR(50) NOT NULL
)
