CREATE TABLE [Manufactory].[SPCV_TechnologicalSequenceJob]
(
	stsj_id                      INT IDENTITY(1, 1) CONSTRAINT [PK_SPCV_TechnologicalSequenceJob] PRIMARY KEY CLUSTERED NOT NULL,
	sts_id                       INT CONSTRAINT [FK_SPCV_TechnologicalSequenceJob_sts_id] FOREIGN KEY REFERENCES Manufactory.SPCV_TechnologicalSequence(sts_id) NOT NULL,
	spcvts_id                    INT CONSTRAINT [FK_SPCV_TechnologicalSequenceJob_spcvts_id] FOREIGN KEY REFERENCES Planing.SketchPlanColorVariantTS(spcvts_id) NOT NULL,
	job_employee_id              INT CONSTRAINT [FK_SPCV_TechnologicalSequenceJob_job_employee_id] FOREIGN KEY REFERENCES Settings.EmployeeSetting(employee_id) NOT NULL,
	plan_cnt                     SMALLINT NOT NULL,
	dt                           DATETIME2(0) NOT NULL,
	employee_id                  INT NOT NULL,
	employee_cnt                 SMALLINT NULL,
	close_cnt                    SMALLINT NULL,
	close_dt                     DATETIME2(0) NULL,
	close_employee_id            INT NULL,
	salary_close_dt              DATETIME2(0) NULL,
	salary_close_employee_id     INT NULL
)

GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_SPCV_TechnologicalSequenceJob_sts_id_spcvts_id_job_employee_id] ON Manufactory.SPCV_TechnologicalSequenceJob(sts_id, spcvts_id, job_employee_id) 
ON [Indexes]

GO 
CREATE NONCLUSTERED INDEX [IX_SPCV_TechnologicalSequenceJob_] ON Manufactory.SPCV_TechnologicalSequenceJob(sts_id, spcvts_id, job_employee_id) INCLUDE(stsj_id, employee_id, plan_cnt, employee_cnt) 
WHERE close_cnt IS NULL AND	employee_cnt IS NOT     NULL ON [Indexes]