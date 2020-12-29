﻿CREATE TYPE [Synchro].[NM_Load_Type] AS TABLE
(
	sa VARCHAR(76) NOT NULL,
	nm_id INT NOT NULL
)
GO

GRANT EXECUTE
    ON TYPE::[Synchro].[NM_Load_Type] TO PUBLIC;
GO