CREATE TABLE [Manufactory].[TaskLayoutStatus]
(
	tls_id          TINYINT CONSTRAINT [PK_TaskLayoutStatus] PRIMARY KEY CLUSTERED NOT NULL,
	tls_name        VARCHAR(50) NOT NULL,
	employee_id     INT NOT NULL,
	dt              DATETIME2(0) NOT NULL
)
