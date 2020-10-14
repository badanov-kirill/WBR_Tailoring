CREATE TABLE [Products].[Languages]
(
	lang_code char(2) CONSTRAINT [PK_Languages] PRIMARY KEY CLUSTERED NOT NULL,
	lang_name NVARCHAR(16) NULL,
	lang_name_ru VARCHAR(16) NULL,
	order_num SMALLINT NOT NULL
)
