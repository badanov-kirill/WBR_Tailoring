CREATE TYPE [SyncFinance].[LoadedId] AS TABLE
(
    id     INT NOT NULL,
    rv     BINARY(8) NOT NULL
)
GO

GRANT EXECUTE
    ON TYPE::[SyncFinance].[LoadedId] TO PUBLIC;
GO