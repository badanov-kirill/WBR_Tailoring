CREATE TABLE [Manufactory].[TaskChinaSample]
(
	tcs_id                 INT IDENTITY(1, 1) CONSTRAINT [PK_TaskChinaSample] PRIMARY KEY CLUSTERED NOT NULL,
	sketch_id              INT CONSTRAINT [FK_TaskChinaSample_sketch_id] FOREIGN KEY REFERENCES Products.Sketch(sketch_id) NOT NULL,
	create_dt              DATETIME2(0) NOT NULL,
	create_employee_id     INT NOT NULL,
	close_dt               DATETIME2(0) NULL,
	close_employee_id      INT NULL,
	comment                VARCHAR(250) NULL
)

GO 
CREATE UNIQUE NONCLUSTERED INDEX [UQ_TaskChinaSample_sketch_id] ON Manufactory.TaskChinaSample(sketch_id) WHERE close_dt IS NULL ON [Indexes]