CREATE TABLE [History].[SHKRawMaterialOnPlace]
(
	log_id          INT IDENTITY(1, 1) CONSTRAINT [PK_History_SHKRawMaterialOnPlace] PRIMARY KEY CLUSTERED NOT NULL,
	shkrm_id        INT NOT NULL,
	place_id        INT NULL,
	dt              DATETIME2(0) NOT NULL,
	employee_id     INT NOT NULL,
	proc_id         INT NULL
)

GO
CREATE NONCLUSTERED INDEX [IX_History_SHKRawMaterialOnPlace_shkrm_id] ON History.SHKRawMaterialOnPlace(shkrm_id) ON [Indexes]