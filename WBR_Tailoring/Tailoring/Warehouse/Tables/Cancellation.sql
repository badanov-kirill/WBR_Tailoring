CREATE TABLE [Warehouse].[Cancellation]
(
	cancellation_id        INT IDENTITY(1, 1) CONSTRAINT [PK_Cancellation] PRIMARY KEY CLUSTERED NOT NULL,
	create_dt              DATETIME2(0) NOT NULL,
	create_employee_id     INT NOT NULL,
	office_id              INT CONSTRAINT [FK_Cancellation_office_id] FOREIGN KEY REFERENCES Settings.OfficeSetting (office_id) NOT NULL,
	cancellation_year      SMALLINT NULL,
	cancellation_month     TINYINT NULL,
	close_employee_id      INT NULL,
	close_dt               DATETIME2(0) NULL,
	cancellation_dt        AS DATEFROMPARTS(cancellation_year, cancellation_month, 1) PERSISTED
)

GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_Cancellation_office_id_cancellation_year_cancellation_month] ON Warehouse.Cancellation(office_id, cancellation_year, cancellation_month) 
ON [Indexes]