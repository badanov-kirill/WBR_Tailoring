﻿CREATE TABLE [Synchro].[Upload_DetMirShip_BuhVas]
(
	sfp_id INT CONSTRAINT [PK_Upload_DetMir_BuhVas] PRIMARY KEY CLUSTERED NOT NULL,
	rv ROWVERSION NOT NULL,
	dt DATETIME2(0) NOT NULL
)
