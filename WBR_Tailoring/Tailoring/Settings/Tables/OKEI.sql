﻿CREATE TABLE [Settings].[OKEI]
(
	okei_id INT CONSTRAINT [FK_Settings_OKEI_okei_id] FOREIGN KEY REFERENCES Qualifiers.OKEI(okei_id) NOT NULL,
	CONSTRAINT [PK_Settings_OKEI] PRIMARY KEY CLUSTERED (okei_id)
)
