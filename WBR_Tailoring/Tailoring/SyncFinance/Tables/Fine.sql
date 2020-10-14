CREATE TABLE [SyncFinance].[Fine]
(
	id                      INT IDENTITY(1, 1) NOT NULL,
	imprest_employee_id     INT NULL,
	cash_sum                DECIMAL(15, 2) NULL,
	currency_id             INT NULL,
	comment                 VARCHAR(500) NULL,
	is_deleted              BIT NOT NULL,
	edit_employee_id        INT NOT NULL,
	approve_employee_id     INT NULL,
	cfo_id                  INT NULL,
	imprest_cfo_id          INT NULL,
	source_type_id          INT NULL,
	source_id               INT NULL,
	context                 INT NULL,
	rv                      ROWVERSION NOT NULL,
	CONSTRAINT PK_Fine PRIMARY KEY CLUSTERED(id),
	CONSTRAINT CH_Fine_is_deleted CHECK(
		(
			is_deleted = 0
			AND cash_sum IS NOT NULL
			AND currency_id IS NOT NULL
			AND approve_employee_id IS NOT NULL
			AND source_type_id IS NOT NULL
			AND source_id IS NOT NULL
			AND context IS NOT NULL
		)
		OR is_deleted = 1
	)
)