CREATE TABLE [History].[SHKRawMaterialReserv]
(
	hshrmr_id       INT IDENTITY(1, 1) CONSTRAINT [PK_SHKRawMaterialReserv] PRIMARY KEY CLUSTERED NOT NULL,
	shkrm_id        INT NOT NULL,
	spcvc_id        INT NOT NULL,
	okei_id         INT NOT NULL,
	quantity        DECIMAL(9, 3) NOT NULL,
	dt              DATETIME2(0) NOT NULL,
	employee_id     INT NOT NULL,
	rmid_id         INT NULL,
	rmodr_id        INT NULL,
	proc_id         INT NOT NULL,
	operation       CHAR(1) NOT NULL
)
