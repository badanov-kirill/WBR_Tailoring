CREATE TABLE [Wildberries].[FieldsRequired]
(
	wb_subject_id     INT CONSTRAINT [FK_FieldsRequired_wb_subject_id] FOREIGN KEY REFERENCES Wildberries.WB_Subjects(wb_subject_id) NOT NULL,
	fields_id         INT CONSTRAINT [FK_FieldsRequired_fields_id] FOREIGN KEY REFERENCES Wildberries.Fields(fields_id) NOT NULL,
	CONSTRAINT [PK_FieldsRequired] PRIMARY KEY CLUSTERED(wb_subject_id, fields_id)
)
