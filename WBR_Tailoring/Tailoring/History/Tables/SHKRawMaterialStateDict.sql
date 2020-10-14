CREATE TABLE [History].[SHKRawMaterialStateDict]
(
	log_id       INT IDENTITY(1, 1) CONSTRAINT [PK_History_SHKRawMaterialStateDict] PRIMARY KEY CLUSTERED NOT NULL,
	state_id        INT NOT NULL,
	state_name      VARCHAR(50) NOT NULL,
	state_descr     VARCHAR(500) NULL,
	dt              dbo.SECONDSTIME NOT NULL,
	employee_id     INT NOT NULL
)
