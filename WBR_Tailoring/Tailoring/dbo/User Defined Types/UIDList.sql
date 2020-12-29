CREATE TYPE [dbo].[UIDList] AS TABLE
(
    char_uid CHAR(36)
);
GO

GRANT EXECUTE
    ON TYPE::[dbo].[UIDList] TO PUBLIC;
GO
