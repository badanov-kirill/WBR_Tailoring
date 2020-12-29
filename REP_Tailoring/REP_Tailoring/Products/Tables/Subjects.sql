CREATE TABLE [Products].[Subjects]
(
	subject_id SMALLINT IDENTITY(1,1) CONSTRAINT [PK_Subjects] PRIMARY KEY CLUSTERED NOT NULL,
	subject_name VARCHAR(50) NOT NULL
)

GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_Subjects_subject_name] ON Products.Subjects(subject_name) INCLUDE(subject_id) ON [Indexes]