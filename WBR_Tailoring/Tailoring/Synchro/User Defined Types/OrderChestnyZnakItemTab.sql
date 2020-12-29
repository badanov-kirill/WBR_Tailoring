CREATE TYPE [Synchro].[OrderChestnyZnakItemTab] AS TABLE
(
	code		NVARCHAR(200) NULL,
	gtin01		VARCHAR(14) NULL,
	serial21	NVARCHAR(20) NULL,
	intrnal91	NVARCHAR(10) NULL,
	intrnal92	NVARCHAR(90) NULL
)

GO
GRANT EXECUTE
    ON TYPE::[Synchro].[OrderChestnyZnakItemTab] TO PUBLIC;
GO