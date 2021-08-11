CREATE TYPE [dbo].[CountList] AS TABLE (
    [id] INT NOT NULL,
    [cnt] INT NOT NULL
    PRIMARY KEY CLUSTERED ([id] ASC));
GO

GRANT EXECUTE
    ON TYPE::[dbo].[CountList] TO PUBLIC;
GO
