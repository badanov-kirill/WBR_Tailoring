CREATE TABLE [Logistics].[Shipping]
(
	shipping_id              INT IDENTITY(1, 1) CONSTRAINT [PK_Shipping] PRIMARY KEY CLUSTERED NOT NULL,
	employee_id              INT NOT NULL,
	dt                       dbo.SECONDSTIME NOT NULL,
	create_employee_id       INT NOT NULL,
	create_dt                dbo.SECONDSTIME NOT NULL,
	close_employee_id        INT NULL,
	close_dt                 dbo.SECONDSTIME NULL,
	src_office_id            INT CONSTRAINT [FK_Shipping_src_office_id] FOREIGN KEY REFERENCES Settings.OfficeSetting(office_id) NOT NULL,
	complite_employee_id     INT NULL,
	complite_dt              dbo.SECONDSTIME NULL,
	is_deleted               BIT NOT NULL,
	rv                       ROWVERSION NOT NULL
)
