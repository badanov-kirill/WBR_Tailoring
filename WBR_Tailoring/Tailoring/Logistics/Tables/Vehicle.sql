CREATE TABLE [Logistics].[Vehicle]
(
	vehicle_id       INT IDENTITY(1, 1) CONSTRAINT [PK_Vehicle] PRIMARY KEY CLUSTERED NOT NULL,
	brand_name       VARCHAR(50) NOT NULL,
	number_plate     VARCHAR(9) NOT NULL,
	dt               dbo.SECONDSTIME NOT NULL,
	employee_id      INT NOT NULL
)

GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_Vehicle_number_plate] ON Logistics.Vehicle(number_plate) ON [Indexes]
