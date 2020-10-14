CREATE TABLE [Planing].[CompletingStatus]
(
	cs_id           TINYINT CONSTRAINT [PK_CompletingStatus] PRIMARY KEY CLUSTERED NOT NULL,
	cs_name         VARCHAR(50) NOT NULL,
	employee_id     INT NOT NULL,
	dt              DATETIME2(0) NOT NULL
)
