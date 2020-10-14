CREATE TABLE [Qualifiers].[OKEI]
(
	okei_id                  INT NOT NULL,
	okei_type_id             INT NOT NULL,
	okei_group_id            INT NOT NULL,
	fullname                 VARCHAR(50) NOT NULL,
	symbol                   VARCHAR(15) NOT NULL,
	symbol_international     VARCHAR(15) NOT NULL,
	code                     VARCHAR(15) NOT NULL,
	code_international       VARCHAR(15) NOT NULL,
	CONSTRAINT PK_Qualifiers_OKEI_okei_id PRIMARY KEY(okei_id),
	CONSTRAINT FK_Qualifiers_OKEI_okei_type_id FOREIGN KEY(okei_type_id) REFERENCES Qualifiers.OKEI_types(okei_type_id),
	CONSTRAINT FK_Qualifiers_OKEI_okei_group_id FOREIGN KEY(okei_group_id) REFERENCES Qualifiers.OKEI_groups(okei_group_id)
)