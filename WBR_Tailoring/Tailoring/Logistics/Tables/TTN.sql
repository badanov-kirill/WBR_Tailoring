CREATE TABLE [Logistics].[TTN]
(
	ttn_id                   INT IDENTITY(1, 1) CONSTRAINT [PK_TTN] PRIMARY KEY CLUSTERED NOT NULL,
	shipping_id              INT CONSTRAINT [FK_TTN_shipping_id] FOREIGN KEY REFERENCES Logistics.Shipping(shipping_id) NOT NULL,
	src_office_id            INT CONSTRAINT [FK_TTN_src_office_id] FOREIGN KEY REFERENCES Settings.OfficeSetting (office_id) NOT NULL,
	dst_office_id            INT CONSTRAINT [FK_TTN_dst_office_id] FOREIGN KEY REFERENCES Settings.OfficeSetting (office_id) NOT NULL,
	seal1                    VARCHAR(20) NULL,
	seal2                    VARCHAR(20) NULL,
	employee_id              INT NOT NULL,
	dt                       dbo.SECONDSTIME NOT NULL,
	vehicle_id               INT CONSTRAINT [FK_TTN_vehicle_id] FOREIGN KEY REFERENCES Logistics.Vehicle(vehicle_id) NOT NULL,
	driver_id                INT CONSTRAINT [FK_TTN_driver_id] FOREIGN KEY REFERENCES Logistics.Driver(driver_id) NOT NULL,
	towed_vehicle_id         INT CONSTRAINT [FK_TTN_towed_vehicle_id] FOREIGN KEY REFERENCES Logistics.Vehicle(vehicle_id) NULL,
	complite_employee_id     INT NULL,
	complite_dt              dbo.SECONDSTIME NULL,
	is_deleted               BIT NOT NULL,
	create_employee_id       INT NOT NULL,
	create_dt                dbo.SECONDSTIME NOT NULL
)

GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_TTN_shipping_id_src_office_id_dst_office_id] ON Logistics.TTN(shipping_id,src_office_id,dst_office_id) ON [Indexes]