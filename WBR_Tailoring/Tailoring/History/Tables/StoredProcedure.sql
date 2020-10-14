CREATE TABLE [History].[StoredProcedure]
(
	proc_id       INT IDENTITY(1, 1) CONSTRAINT [PK_StoredProcedure] PRIMARY KEY CLUSTERED NOT NULL,
	proc_name     VARCHAR(257) NOT NULL
)

GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_StoredProcedure_proc_name] ON History.StoredProcedure(proc_name) ON [Indexes]