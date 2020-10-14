CREATE TABLE [Wildberries].[WB_SubjectParensts]
(
	wb_subject_parent_id INT CONSTRAINT [PK_WB_SubjectParrensts] PRIMARY KEY CLUSTERED NOT NULL,
	wb_subject_parent_name VARCHAR(100) NOT NULL,
	dt DATETIME2(0)
)
