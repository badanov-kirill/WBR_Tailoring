CREATE TABLE [Manufactory].[CuttingActualEmployee]
(
	cae_id          INT IDENTITY(1, 1) CONSTRAINT [PK_CuttingActualEmployee] PRIMARY KEY CLUSTERED NOT NULL,
	ca_id           INT CONSTRAINT [FK_CuttingActualEmployee_ca_id] FOREIGN KEY REFERENCES Manufactory.CuttingActual(ca_id) NOT NULL,
	employee_id     INT NOT NULL
)

GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_CuttingActualEmployee_employee_id_ca_id] ON Manufactory.CuttingActualEmployee(ca_id, employee_id) ON [Indexes]

