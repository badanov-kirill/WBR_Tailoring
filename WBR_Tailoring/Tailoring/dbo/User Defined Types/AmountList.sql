CREATE TYPE [dbo].[AmountList] AS TABLE (
    [id] INT NOT NULL,
    [amount] DECIMAL(9,2) NOT NULL
    PRIMARY KEY CLUSTERED ([id] ASC));
GO

GRANT EXECUTE
    ON TYPE::[dbo].[AmountList] TO PUBLIC;
GO
