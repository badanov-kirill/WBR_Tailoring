CREATE TABLE [Logistics].[PackingBox]
(
	packing_box_id         INT IDENTITY(1, 1) CONSTRAINT [PK_PackingBox] PRIMARY KEY CLUSTERED NOT NULL,
	create_dt              DATETIME2(0) NOT NULL,
	create_employee_id     INT NOT NULL,
	start_packaging_dt     DATETIME2(0) NULL,
	close_dt               DATETIME2(0) NULL,
	close_employee_id      INT NULL
)
