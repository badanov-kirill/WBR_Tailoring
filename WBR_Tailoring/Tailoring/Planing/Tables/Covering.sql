CREATE TABLE [Planing].[Covering]
(
	covering_id            INT IDENTITY(1, 1) CONSTRAINT [PK_Covering] PRIMARY KEY CLUSTERED NOT NULL,
	create_dt              DATETIME2(0) NOT NULL,
	create_employee_id     INT NOT NULL,
	office_id              INT NOT NULL,
	close_dt               DATETIME2(0) NULL,
	close_employee_id      INT NULL,
	cost_dt                DATETIME2(0) NULL,
	cost_employee_id       INT NULL,
	cutting_dt             DATETIME2(0) NULL
)