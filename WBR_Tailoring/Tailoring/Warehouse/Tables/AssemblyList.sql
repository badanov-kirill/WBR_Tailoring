CREATE TABLE [Warehouse].[AssemblyList]
(
	al_id                  INT IDENTITY(1, 1) CONSTRAINT [PK_AssemblyList] PRIMARY KEY CLUSTERED NOT NULL,
	create_dt              DATETIME2(0) NOT NULL,
	create_employee_id     INT NOT NULL,
	workshop_id            INT CONSTRAINT [FK_AssemblyList] FOREIGN KEY REFERENCES Warehouse.Workshop(workshop_id) NULL,
	shipping_dt            DATE NULL,
	close_dt               DATETIME2(0) NULL,
	close_employee_id      INT NULL,
	rv                     ROWVERSION NOT NULL,
	dt                     DATETIME2(0) NOT NULL,
	employee_id            INT NOT NULL
)
