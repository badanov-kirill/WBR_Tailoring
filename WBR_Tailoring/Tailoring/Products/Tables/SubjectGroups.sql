CREATE TABLE [Products].[SubjectGroups]
(
	subject_erp_id     INT CONSTRAINT [PK_SubjectGroups] PRIMARY KEY CLUSTERED NOT NULL,
	group_id           INT CONSTRAINT [FK_SubjectGroups_group_id] FOREIGN KEY REFERENCES Products.SubjectGroupType (group_id) NOT NULL
)
