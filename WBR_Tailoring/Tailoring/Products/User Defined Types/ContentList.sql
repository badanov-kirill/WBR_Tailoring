CREATE TYPE [Products].[ContentList] AS TABLE
(
    contents_id       INT NULL,
    contents_name     VARCHAR(50) NOT NULL
)
GO

GRANT EXECUTE
    ON TYPE::[Products].[ContentList] TO PUBLIC;
GO

