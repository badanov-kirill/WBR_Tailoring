CREATE TABLE [Wildberries].[FieldsLocaleNames]
(
	fields_id INT CONSTRAINT [FK_FieldsLocaleNames_fields_id] FOREIGN KEY REFERENCES Wildberries.Fields(fields_id) NOT NULL,
	locale_cod CHAR(2) NOT NULL,
	fields_locale_name NVARCHAR(200) NOT NULL,
	CONSTRAINT [PK_FieldsLocaleNames] PRIMARY KEY CLUSTERED(fields_id, locale_cod)
)
