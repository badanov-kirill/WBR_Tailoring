CREATE TABLE [Planing].[TaskSelectionPassport]
(
	tsp_id                 INT IDENTITY(1, 1) CONSTRAINT [PK_TaskSelectionPassport] PRIMARY KEY CLUSTERED NOT NULL,
	create_dt              DATETIME2(0) NOT NULL,
	create_employee_id     INT NOT NULL,
	print_dt               DATETIME2(0) NULL,
	print_employee_id      INT NULL,
	close_dt               DATETIME2(0) NULL,
	close_employee_id      INT NULL,
	spcv_id                INT CONSTRAINT [FK_TaskSelectionPassport] FOREIGN KEY REFERENCES Planing.SketchPlanColorVariant(spcv_id) NULL
)

GO
CREATE NONCLUSTERED INDEX [IX_TaskSelectionPassport_spcv_id] ON  Planing.TaskSelectionPassport(spcv_id) ON [Indexes]