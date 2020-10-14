CREATE TABLE [Warehouse].[ImprestSample]
(
	is_id                   INT IDENTITY(1, 1) CONSTRAINT [PK_ImprestSample] PRIMARY KEY CLUSTERED NOT NULL,
	imprest_id              INT CONSTRAINT [FK_ImprestSample_imprest_id] FOREIGN KEY REFERENCES Warehouse.Imprest(imprest_id) NOT NULL,
	sample_id               INT CONSTRAINT [FK_ImprestSample] FOREIGN KEY REFERENCES Manufactory.[Sample](sample_id) NOT NULL,
	shkrm_sample_amount     DECIMAL(15, 2) NULL,
	other_amount            DECIMAL(15, 2) NULL,
	comment                 VARCHAR(200) NULL,
	dt                      DATETIME2(0) NOT NULL,
	employee_id             INT NOT NULL
)

GO 
CREATE UNIQUE NONCLUSTERED INDEX [UQ_ImprestSample_imprest_id_sample_id] ON Warehouse.ImprestSample(sample_id) ON [Indexes]