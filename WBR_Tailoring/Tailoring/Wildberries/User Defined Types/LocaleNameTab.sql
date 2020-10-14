CREATE TYPE [Wildberries].[LocaleNameTab] AS TABLE
(
	fields_id INT NOT NULL,
    locale_cod CHAR(2) NOT NULL, 
    fields_locale_name NVARCHAR(200) NOT NULL,
    PRIMARY KEY CLUSTERED (fields_id, locale_cod)
);
GO

GRANT EXECUTE
    ON TYPE::[Wildberries].[LocaleNameTab] TO PUBLIC;
GO
