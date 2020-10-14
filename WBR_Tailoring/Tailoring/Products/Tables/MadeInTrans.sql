CREATE TABLE [Products].[MadeInTrans]
(
	lang_code               CHAR(2) CONSTRAINT [FK_MadeInTrans_lang_code] FOREIGN KEY REFERENCES Products.Languages(lang_code) NOT NULL,
	made_in_russia_text     NVARCHAR(100) NOT NULL,
	employee_id             INT,
	dt                      DATETIME2(0) NOT NULL,
	CONSTRAINT [PK_MadeInTrans] PRIMARY KEY CLUSTERED(lang_code)
)
