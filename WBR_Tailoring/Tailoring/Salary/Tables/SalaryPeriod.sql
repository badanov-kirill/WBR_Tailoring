CREATE TABLE [Salary].[SalaryPeriod]
(
	salary_period_id             INT IDENTITY(1, 1) CONSTRAINT [PK_SalaryPeriod] PRIMARY KEY CLUSTERED NOT NULL,
	salary_year                  SMALLINT NOT NULL,
	salary_month                 TINYINT NOT NULL,
	close_period_dt              DATETIME2(0) NULL,
	close_period_employee_id     INT NULL
)

GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_SalaryPeriod_salary_year_salary_month] ON Salary.SalaryPeriod(salary_year, salary_month) ON [Indexes]