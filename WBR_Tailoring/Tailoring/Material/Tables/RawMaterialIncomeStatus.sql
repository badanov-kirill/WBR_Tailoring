CREATE TABLE [Material].[RawMaterialIncomeStatus]
(
	rmis_id         INT CONSTRAINT [PK_RawMaterialIncomeStatus] PRIMARY KEY CLUSTERED NOT NULL,
	rmis_name       VARCHAR(50) NOT NULL,
	dt              dbo.SECONDSTIME NOT NULL,
	employee_id     INT NOT NULL
)

GO

CREATE UNIQUE NONCLUSTERED INDEX [UQ_RawMaterialIncomeStatus_rmis_name] ON Material.RawMaterialIncomeStatus(rmis_name) ON [Indexes]