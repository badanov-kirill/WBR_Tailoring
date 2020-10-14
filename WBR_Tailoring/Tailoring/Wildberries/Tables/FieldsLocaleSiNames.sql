CREATE TABLE [Wildberries].[FieldsLocaleSiNames]
(
	fields_id INT CONSTRAINT [FK_FieldsLocaleSiNames_fields_id] FOREIGN KEY REFERENCES Wildberries.Fields(fields_id) NOT NULL,
	locale_cod CHAR(2) NOT NULL,
	fields_locale_si_name NVARCHAR(50) NOT NULL,
	CONSTRAINT [PK_FieldsLocaleSiNames] PRIMARY KEY CLUSTERED(fields_id, locale_cod)
)
