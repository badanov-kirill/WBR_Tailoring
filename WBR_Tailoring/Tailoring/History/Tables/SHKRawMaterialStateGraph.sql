CREATE TABLE [History].[SHKRawMaterialStateGraph]
(
	log_id           INT IDENTITY(1, 1) CONSTRAINT [PK_History_SHKRawMaterialStateGraph] PRIMARY KEY CLUSTERED NOT NULL,
	state_src_id     INT NOT NULL,
	state_dst_id     INT NOT NULL,
	dt               dbo.SECONDSTIME NOT NULL,
	employee_id      INT NOT NULL,
	is_deleted       BIT NOT NULL
)
