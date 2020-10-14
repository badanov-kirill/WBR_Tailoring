CREATE TABLE [Products].[ConsistsTrans]
(
	consist_id       INT CONSTRAINT [FK_ConsistsTrans_consist_id] FOREIGN KEY REFERENCES Products.Consist(consist_id) NOT NULL,
	lang_code        CHAR(2) CONSTRAINT [FK_ConsistsTrans_lang_code] FOREIGN KEY REFERENCES Products.Languages(lang_code) NOT NULL,
	consist_name     NVARCHAR(50) NOT NULL,
	employee_id      INT NOT NULL,
	dt               DATETIME2(0) NOT NULL,
	CONSTRAINT [PK_ConsistTrans] PRIMARY KEY CLUSTERED(consist_id, lang_code)
)
