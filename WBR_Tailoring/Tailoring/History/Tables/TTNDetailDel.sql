CREATE TABLE [History].[TTNDetailDel]
(
	log_id          INT IDENTITY(1, 1) CONSTRAINT [PK_TTNDetailDel] PRIMARY KEY CLUSTERED NOT NULL,
	ttn_id          INT NOT NULL,
	shkrm_id        INT NOT NULL,
	employee_id     INT NOT NULL,
	dt              DATETIME2(0) NOT NULL
)
