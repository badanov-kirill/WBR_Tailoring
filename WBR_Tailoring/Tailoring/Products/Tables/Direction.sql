CREATE TABLE [Products].[Direction]
(
	direction_id       INT IDENTITY(1, 1) CONSTRAINT [PK_Direction] PRIMARY KEY CLUSTERED NOT NULL,
	direction_name     VARCHAR(50) NOT NULL,
	employee_id        INT NOT NULL,
	dt                 dbo.SECONDSTIME NOT NULL,
	is_deleted         BIT NOT NULL,
	erp_id             INT NOT NULL
)
GO

CREATE UNIQUE NONCLUSTERED INDEX [UQ_Direction_direction_name] ON Products.Direction(direction_name) WHERE is_deleted = 0 ON [Indexes]
GO
