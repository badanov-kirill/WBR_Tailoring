CREATE TABLE [Products].[SubjectAddedOption]
(
	subject_id        INT CONSTRAINT [FK_SubjectAddedOption_subject_id] FOREIGN KEY REFERENCES Products.[Subject] (subject_id) NOT NULL,
	ao_id             INT CONSTRAINT [FK_SubjectAddedOption_ao_id] FOREIGN KEY REFERENCES Products.AddedOption (ao_id) NOT NULL,
	dt                [dbo].[SECONDSTIME] NOT NULL,
	employee_id       INT NOT NULL,
	required_mode     TINYINT NOT NULL,
	is_sketch         BIT CONSTRAINT [DF_SubjectAddedOption_is_sketch] DEFAULT(0) NOT NULL,
	CONSTRAINT [PK_SubjectAddedOption] PRIMARY KEY CLUSTERED(subject_id, ao_id)
)