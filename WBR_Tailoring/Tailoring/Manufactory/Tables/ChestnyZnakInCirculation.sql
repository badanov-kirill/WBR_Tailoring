﻿CREATE TABLE [Manufactory].[ChestnyZnakInCirculation]
(
	czic_id INT IDENTITY(1,1) CONSTRAINT [PK_ChestnyZnakInCirculation] PRIMARY KEY CLUSTERED NOT NULL,
	dt DATETIME2(0) NOT NULL,
	employee_id INT NOT NULL,
	dt_send DATETIME2(0) NULL,
	number_cz BINARY(16) NULL,
	fabricator_id INT NULL CONSTRAINT [FK_ChestnyZnakInCirculation_fabricator_id] FOREIGN KEY REFERENCES Settings.Fabricators(fabricator_id)
)
