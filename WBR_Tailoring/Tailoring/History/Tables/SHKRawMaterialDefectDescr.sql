CREATE TABLE [History].[SHKRawMaterialDefectDescr]
(
	log_id          INT IDENTITY(1, 1) CONSTRAINT [PK_History_SHKRawMaterialDefectDescr] PRIMARY KEY CLUSTERED NOT NULL,
	shkrm_id        INT NOT NULL,
	descr           VARCHAR(900) NULL,
	dt              dbo.SECONDSTIME NOT NULL,
	employee_id     INT NOT NULL,
	proc_id         INT NOT NULL
)
