CREATE TYPE [Ozon].[CategoryesType] AS TABLE
(
	category_id             BIGINT NOT NULL,
	category_parrent_id     BIGINT NULL,
	category_name           VARCHAR(100)
)
GO

GRANT EXECUTE
    ON TYPE::[Ozon].[CategoryesType] TO PUBLIC;
GO