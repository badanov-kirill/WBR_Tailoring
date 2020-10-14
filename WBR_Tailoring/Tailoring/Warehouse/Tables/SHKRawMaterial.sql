CREATE TABLE [Warehouse].[SHKRawMaterial]
(
	shkrm_id        INT IDENTITY(1, 1) CONSTRAINT [PK_SHKRawMaterial] PRIMARY KEY CLUSTERED NOT NULL,
	employee_id     INT NOT NULL,
	dt              dbo.SECONDSTIME NOT NULL,
	dt_mapping      DATETIME2(0) NULL
)

GO