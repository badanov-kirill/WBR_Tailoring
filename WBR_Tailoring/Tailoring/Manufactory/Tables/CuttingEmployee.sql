CREATE TABLE [Manufactory].[CuttingEmployee]
(
	ce_id           INT IDENTITY(1, 1) CONSTRAINT [PK_CuttingEmployee] PRIMARY KEY CLUSTERED NOT NULL,
	cutting_id      INT CONSTRAINT [FK_CuttingEmployee_cutting_id] FOREIGN KEY REFERENCES Manufactory.Cutting(cutting_id) NOT NULL,
	employee_id     INT NOT NULL
)	
GO

CREATE UNIQUE NONCLUSTERED INDEX [UQ_CuttingEmployee_cutting_id_employee_id] ON Manufactory.CuttingEmployee(employee_id, cutting_id) ON [Indexes]