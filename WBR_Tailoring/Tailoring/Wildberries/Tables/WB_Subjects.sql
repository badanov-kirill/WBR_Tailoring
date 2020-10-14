CREATE TABLE [Wildberries].[WB_Subjects]
(
	wb_subject_id INT CONSTRAINT [PK_WB_Subjects] PRIMARY KEY CLUSTERED NOT NULL,
	wb_subject_name NVARCHAR(100) NOT NULL,
	is_deleted BIT NOT NULL,
	wb_subject_parent_id INT CONSTRAINT [FK_WB_Subjects_wb_subject_parent_id] FOREIGN KEY REFERENCES Wildberries.WB_SubjectParensts(wb_subject_parent_id) NULL,
	dt DATETIME2(0)
)

GO 
CREATE UNIQUE NONCLUSTERED INDEX [UQ_WB_Subjects_wb_subject_name] ON Wildberries.WB_Subjects(wb_subject_name) WHERE is_deleted = 0 ON [Indexes]