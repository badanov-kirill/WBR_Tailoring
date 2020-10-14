CREATE TABLE [Warehouse].[SampleOnPlace]
(
	sample_id       INT CONSTRAINT [FK_SampleOnPlace_Sample_id] FOREIGN KEY REFERENCES Manufactory.[Sample](sample_id) NOT NULL,
	place_id        INT CONSTRAINT [FK_Sample_place_id] FOREIGN KEY REFERENCES Warehouse.StoragePlace(place_id) NOT NULL,
	dt              dbo.SECONDSTIME NOT NULL,
	employee_id     INT NOT NULL,
	rv              ROWVERSION NOT NULL,
	CONSTRAINT [PK_SampleOnPlace] PRIMARY KEY CLUSTERED(sample_id ASC)
)
