CREATE TYPE [Wildberries].[LoadNomenclatureTab] AS TABLE
(
	sa_nm VARCHAR(36),
	nm_id INT,
	PRIMARY KEY CLUSTERED(sa_nm)
);
GO

GRANT EXECUTE
    ON TYPE::[Wildberries].[LoadNomenclatureTab] TO PUBLIC;
GO