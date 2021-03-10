CREATE TABLE [Manufactory].[ChestnyZnakReturnCirculation]
(
	czrc_id         INT IDENTITY(1, 1) CONSTRAINT [PK_ChestnyZnakReturnCirculation] PRIMARY KEY CLUSTERED NOT NULL,
	employee_id     INT NOT NULL,
	fiscal_num      INT NOT NULL,
	cr_id           INT CONSTRAINT [FK_ChestnyZnakReturnCirculation_cr_id] FOREIGN KEY REFERENCES RefBook.CashReg(cr_id) NOT NULL,
	fa_id           INT CONSTRAINT [FK_ChestnyZnakReturnCirculation_fa_id] FOREIGN KEY REFERENCES RefBook.FiscalAccumulator(fa_id) NOT NULL,
	fiscal_dt       DATE NOT NULL,
	dt_create       DATETIME2(0) NOT NULL,
	dt_send         DATETIME2(0) NULL,
	number_cz       BINARY(16) NULL
)

