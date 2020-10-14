CREATE TABLE [History].[RawMaterialIncomeStatus]
(
	log_id          INT IDENTITY(1, 1) CONSTRAINT [PK_Histoty_RawMaterialIncomeStatus] PRIMARY KEY CLUSTERED NOT NULL,
	rmis_id         INT NOT NULL,
	rmis_name       VARCHAR(50) NOT NULL,
	dt              dbo.SECONDSTIME NOT NULL,
	employee_id     INT NOT NULL
)
