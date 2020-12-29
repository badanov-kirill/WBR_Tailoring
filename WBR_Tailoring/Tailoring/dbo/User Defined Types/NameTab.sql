﻿CREATE TYPE [dbo].[NameTab] AS TABLE
(obj_name VARCHAR(200) NOT NULL, PRIMARY KEY CLUSTERED(obj_name ASC))
GO

GRANT EXECUTE
    ON TYPE::[dbo].[NameTab] TO PUBLIC;
GO
