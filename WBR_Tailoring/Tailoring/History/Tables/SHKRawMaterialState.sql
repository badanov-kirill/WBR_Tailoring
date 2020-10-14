CREATE TABLE [History].[SHKRawMaterialState]
(
	log_id          INT IDENTITY(1, 1) CONSTRAINT [PK_History_SHKRawMaterialState] PRIMARY KEY CLUSTERED NOT NULL,
	shkrm_id        INT NOT NULL,
	state_id        INT NULL,
	dt              DATETIME2(0) NOT NULL,
	employee_id     INT NOT NULL,
	proc_id         INT NOT NULL
)

GO
CREATE NONCLUSTERED INDEX [IX_History_SHKRawMaterialState_shkrm_id] ON History.SHKRawMaterialState(shkrm_id) ON [Indexes]