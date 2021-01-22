CREATE TYPE [Ozon].[CategoryesType] AS TABLE
(
	category_id             INT NOT NULL,
	caregory_parrent_id     INT NULL,
	category_name           VARCHAR(100)
)
GO

GRANT EXECUTE
    ON TYPE::[Ozon].[CategoryesType] TO PUBLIC;
GO