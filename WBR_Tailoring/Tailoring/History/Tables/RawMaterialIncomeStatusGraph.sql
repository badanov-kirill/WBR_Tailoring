CREATE TABLE [History].[RawMaterialIncomeStatusGraph]
(
	log_id          INT IDENTITY(1, 1) CONSTRAINT [PK_History_RawMaterialIncomeStatusGraph] PRIMARY KEY CLUSTERED NOT NULL,
	rmis_src_id     INT NOT NULL,
	rmis_dst_id     INT NOT NULL,
	dt              dbo.SECONDSTIME NOT NULL,
	employee_id     INT NOT NULL,
	is_deleted      BIT NOT NULL
)
