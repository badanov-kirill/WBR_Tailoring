CREATE TABLE [Manufactory].[ChestnyZnakOutCirculation]
(
	czoc_id          INT IDENTITY(1, 1) CONSTRAINT [PK_ChestnyZnakOutCirculation] PRIMARY KEY CLUSTERED NOT NULL,
	employee_id      INT NOT NULL,
	dt_operation     DATETIME2(0) NOT NULL,
	dt_create        DATETIME2(0) NOT NULL,
	dt_send          DATETIME2(0) NULL,
	number_cz        BINARY(16) NULL
)
