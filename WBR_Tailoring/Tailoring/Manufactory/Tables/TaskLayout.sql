CREATE TABLE [Manufactory].[TaskLayout]
(
	tl_id                  INT IDENTITY(1, 1) CONSTRAINT [PK_TaskLayout] PRIMARY KEY CLUSTERED NOT NULL,
	create_dt              DATETIME2(0) NOT NULL,
	create_employee_id     INT NOT NULL,
	dt                     DATETIME2(0) NOT NULL,
	employee_id            INT NOT NULL,
	spcv_id                INT CONSTRAINT [FK_TaskLayout_spcv_id] FOREIGN KEY REFERENCES Planing.SketchPlanColorVariant(spcv_id) NOT NULL,
	tls_id                 TINYINT CONSTRAINT [FK_TaskLayout_tls_id] FOREIGN KEY REFERENCES Manufactory.TaskLayoutStatus(tls_id) NOT NULL
)

GO
CREATE NONCLUSTERED INDEX [IX_TaskLayout_spcv_id_tls_id] ON Manufactory.TaskLayout(spcv_id, tls_id) ON [Indexes]
GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_TaskLayout_spcv_id_tls_id] ON Manufactory.TaskLayout(spcv_id) WHERE tls_id = 1 ON [Indexes]