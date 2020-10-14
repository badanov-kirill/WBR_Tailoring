CREATE TABLE [History].[PackingBoxOnPlace]
(
	log_id             INT IDENTITY(1, 1) CONSTRAINT [PK_History_PackingBoxOnPlace] PRIMARY KEY CLUSTERED NOT NULL,
	packing_box_id     INT NOT NULL,
	place_id           INT NULL,
	dt                 DATETIME2(0) NOT NULL,
	employee_id        INT NOT NULL,
	proc_id            INT NULL
)

GO
CREATE NONCLUSTERED INDEX [IX_History_PackingBoxOnPlace_packing_box_id] ON History.PackingBoxOnPlace(packing_box_id) ON [Indexes]