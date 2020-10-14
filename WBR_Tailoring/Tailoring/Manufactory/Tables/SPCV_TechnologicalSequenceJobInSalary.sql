CREATE TABLE [Manufactory].[SPCV_TechnologicalSequenceJobInSalary]
(
	stsjs_id             INT IDENTITY(1, 1) CONSTRAINT [PK_SPCV_TechnologicalSequenceJobInSalary] PRIMARY KEY CLUSTERED NOT NULL,
	stsj_id              INT CONSTRAINT [FK_SPCV_TechnologicalSequenceJobInSalary_stsj_id] FOREIGN KEY REFERENCES Manufactory.SPCV_TechnologicalSequenceJob(stsj_id) NOT NULL,
	salary_period_id     INT CONSTRAINT [FK_SPCV_TechnologicalSequenceJobInSalary_salary_period_id] FOREIGN KEY REFERENCES Salary.SalaryPeriod(salary_period_id) NOT NULL,
	cnt                  DECIMAL(9, 5) NOT NULL,
	amount               DECIMAL(9, 2) NOT NULL,
	dt                   DATETIME2(0) NOT NULL,
	employee_id          INT NOT NULL
)

GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_SPCV_TechnologicalSequenceJobInSalary_stsj_id_salary_period_id_inc_cnt_am] ON Manufactory.SPCV_TechnologicalSequenceJobInSalary(stsj_id, salary_period_id) 
INCLUDE(cnt, amount) ON [Indexes]

GO
CREATE NONCLUSTERED INDEX [UQ_SPCV_TechnologicalSequenceJobInSalary_salary_period_id_stsjs_id] ON [Manufactory].[SPCV_TechnologicalSequenceJobInSalary] (salary_period_id, stsjs_id)
INCLUDE(cnt, amount) ON [Indexes]