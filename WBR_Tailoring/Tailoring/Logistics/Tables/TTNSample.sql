CREATE TABLE [Logistics].[TTNSample]
(
	ttns_id         INT IDENTITY(1, 1) CONSTRAINT [PK_TTNSample] PRIMARY KEY CLUSTERED NOT NULL,
	ttn_id          INT CONSTRAINT [FK_TTNSample_ttn_id] FOREIGN KEY REFERENCES Logistics.TTN(ttn_id) NOT NULL,
	sample_id       INT CONSTRAINT [FK_TTNSample_sample_id] FOREIGN KEY REFERENCES Manufactory.[Sample](sample_id) NOT NULL,
	employee_id     INT NOT NULL,
	dt              dbo.SECONDSTIME NOT NULL,
)

GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_TTNSample_ttn_id_sample_id] ON Logistics.TTNSample(ttn_id, sample_id) ON [Indexes]