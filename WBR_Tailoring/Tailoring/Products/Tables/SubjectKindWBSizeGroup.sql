CREATE TABLE [Products].[SubjectKindWbSizeGroup]
(
	subject_id           INT CONSTRAINT [FK_SubjectKindWbSizeGroup_subject_id] FOREIGN KEY REFERENCES Products.[Subject](subject_id) NOT NULL,
	kind_id              INT CONSTRAINT [FK_SubjectKindWbSizeGroup_kind_id] FOREIGN KEY REFERENCES Products.Kind(kind_id) NOT NULL,
	wb_size_group_id     INT CONSTRAINT [FK_SubjectKindWbSizeGroup_wb_size_group_id] FOREIGN KEY REFERENCES Products.WbSizeGroup(wb_size_group_id) NOT NULL,
	dt                   dbo.SECONDSTIME NOT NULL,
	employee_id          INT NOT NULL,
	CONSTRAINT [PK_SubjectKindWbSizeGroup] PRIMARY KEY CLUSTERED(subject_id, kind_id, wb_size_group_id)
)
