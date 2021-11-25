CREATE TYPE [Wildberries].[LoadNomenclatureTab] AS TABLE
(
	sa_nm VARCHAR(36),
	nm_id INT,
	nm_uid VARCHAR(36),
	PRIMARY KEY CLUSTERED(sa_nm)
);
GO

GRANT EXECUTE
    ON TYPE::[Wildberries].[LoadNomenclatureTab] TO PUBLIC;
GO