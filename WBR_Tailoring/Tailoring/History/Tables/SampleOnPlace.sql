CREATE TABLE [History].[SampleOnPlace]
(
	log_id          INT IDENTITY(1, 1) CONSTRAINT [PK_History_SampleOnPlace] PRIMARY KEY CLUSTERED NOT NULL,
	sample_id        INT NOT NULL,
	place_id        INT NULL,
	dt              DATETIME2(0) NOT NULL,
	employee_id     INT NOT NULL,
	proc_id         INT NULL
)

GO
CREATE NONCLUSTERED INDEX [IX_History_SampleOnPlace_sample_id] ON History.SampleOnPlace(sample_id) ON [Indexes]