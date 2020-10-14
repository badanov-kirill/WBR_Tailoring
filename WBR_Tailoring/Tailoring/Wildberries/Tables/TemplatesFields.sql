CREATE TABLE [Wildberries].[TemplatesFields]
(
	template_id       INT CONSTRAINT [FK_TemplatesFields_template_id] FOREIGN KEY REFERENCES Wildberries.Templates(template_id) NOT NULL,
	fields_id     INT CONSTRAINT [FK_TemplatesFields_fields_id] FOREIGN KEY REFERENCES Wildberries.Fields(fields_id) NOT NULL,
	CONSTRAINT [PK_TemplatesFields] PRIMARY KEY CLUSTERED(template_id, fields_id)
)
