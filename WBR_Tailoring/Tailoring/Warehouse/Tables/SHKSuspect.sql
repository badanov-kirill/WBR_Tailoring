CREATE TABLE [Warehouse].[SHKSuspect]
(
	shks_id         INT NOT NULL IDENTITY(1, 1) CONSTRAINT [PK_SHKSuspect] PRIMARY KEY CLUSTERED,
	dt              DATETIME2(0) NOT NULL,
	employee_id     INT NOT NULL
)
GO