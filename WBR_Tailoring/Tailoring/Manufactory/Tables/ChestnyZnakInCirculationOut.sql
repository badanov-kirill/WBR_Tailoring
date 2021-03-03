CREATE TABLE [Manufactory].[ChestnyZnakInCirculationOut]
(
	czco_id         INT IDENTITY(1, 1) CONSTRAINT [PK_ChestnyZnakInCirculationOut] PRIMARY KEY CLUSTERED NOT NULL,
	employee_id     INT NOT NULL,
	dt              DATETIME2(0) NOT NULL,
	dt_send         DATETIME2(0) NULL,
	number_cz       BINARY(16) NULL
)
