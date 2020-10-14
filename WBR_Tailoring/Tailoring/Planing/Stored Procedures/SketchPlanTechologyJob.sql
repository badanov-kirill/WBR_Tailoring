CREATE TABLE [Planing].[SketchPlanTechologyJob]
(
	sptj_id       INT IDENTITY(1, 1) CONSTRAINT [PK_SketchPlanTechologyJob] PRIMARY KEY CLUSTERED NOT NULL,
	sp_id         INT CONSTRAINT [FK_SketchPlanTechologyJob_sp_id] FOREIGN KEY REFERENCES Planing.SketchPlan(sp_id) NOT NULL,
	stj_id        INT CONSTRAINT [FK_SketchPlanTechologyJob_stj_id] FOREIGN KEY REFERENCES Products.SketchTechnologyJob(stj_id) NOT NULL,
	create_dt     DATETIME2(0) NOT NULL
)

GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_SketchPlanTechologyJob_sp_id] ON [Planing].[SketchPlanTechologyJob](sp_id) ON [Indexes]