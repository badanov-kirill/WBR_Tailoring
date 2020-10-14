CREATE TABLE [Wildberries].[TemplatesSubjects]
(
	template_id       INT CONSTRAINT [FK_TemplatesSubjects_template_id] FOREIGN KEY REFERENCES Wildberries.Templates(template_id) NOT NULL,
	wb_subject_id     INT CONSTRAINT [FK_TemplatesSubjects_wb_subject_id] FOREIGN KEY REFERENCES Wildberries.WB_Subjects(wb_subject_id) NOT NULL,
	CONSTRAINT [PK_TemplatesSubjects] PRIMARY KEY CLUSTERED(template_id, wb_subject_id)
)
