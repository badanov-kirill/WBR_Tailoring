CREATE TABLE [Warehouse].[Imprest]
(
	imprest_id              INT IDENTITY(1, 1) CONSTRAINT [PK_Imprest] PRIMARY KEY CLUSTERED NOT NULL,
	create_dt               DATETIME2(0) NOT NULL,
	create_employee_id      INT NOT NULL,
	imprest_office_id       INT CONSTRAINT [FK_Imprest_office_id] FOREIGN KEY REFERENCES Settings.OfficeSetting (office_id) NOT NULL,
	imprest_employee_id     INT NOT NULL,
	comment                 VARCHAR(500) NULL,
	is_deleted              BIT NOT NULL,
	edit_employee_id        INT NOT NULL,
	approve_employee_id     INT NULL,
	approve_dt              DATETIME2(0) NULL,
	rv                      ROWVERSION NOT NULL,
	cash_sum                DECIMAL(15, 2) NULL
)
