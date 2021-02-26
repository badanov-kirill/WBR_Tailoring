CREATE TABLE [Manufactory].[ContractorSewCount]
(
	csc_id INT IDENTITY(1,1) CONSTRAINT [PK_ContractorSewCount] PRIMARY KEY CLUSTERED NOT NULL,
	spcvts_id INT CONSTRAINT [FK_ContractorSewCount_spcvts_id] FOREIGN KEY REFERENCES Planing.SketchPlanColorVariantTS(spcvts_id) NOT NULL,
	cnt INT NOT NULL,
	employee_id INT NOT NULL,
	dt DATETIME2(0) NOT NULL
)

GO
CREATE NONCLUSTERED INDEX [IX_ContractorSewCount_spcvts_id] ON Manufactory.ContractorSewCount(spcvts_id) INCLUDE(cnt) ON [Indexes]