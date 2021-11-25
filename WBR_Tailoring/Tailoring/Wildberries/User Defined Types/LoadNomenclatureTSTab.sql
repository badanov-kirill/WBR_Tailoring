CREATE TYPE [Wildberries].[LoadNomenclatureTSTab] AS TABLE
(
	chrt_id INT,
	nm_id INT,
	ts_name VARCHAR(15),
	chrt_uid VARCHAR(36),
	PRIMARY KEY CLUSTERED(chrt_id)
);
GO

GRANT EXECUTE
    ON TYPE::[Wildberries].[LoadNomenclatureTSTab] TO PUBLIC;
GO