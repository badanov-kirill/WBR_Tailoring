CREATE TABLE [Logistics].[Driver]
(
	driver_id       INT IDENTITY(1, 1) CONSTRAINT [PK_Driver] PRIMARY KEY CLUSTERED NOT NULL,
	driver_name     VARCHAR(100) NOT NULL,
	dt              dbo.SECONDSTIME NOT NULL,
	employee_id     INT NOT NULL
)

GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_Driver_driver_name] ON Logistics.Driver(driver_name) ON [Indexes]