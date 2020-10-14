CREATE TABLE [Planing].[CoveringDetail]
(
	cd_id           INT IDENTITY(1, 1) CONSTRAINT [PK_CoveriongDetail] PRIMARY KEY CLUSTERED NOT NULL,
	covering_id     INT CONSTRAINT [FK_CoveringDetail_covering_id] FOREIGN KEY REFERENCES Planing.Covering(covering_id) NOT NULL,
	spcv_id         INT CONSTRAINT [FK_CoveringDetail_spcv_id] FOREIGN KEY REFERENCES Planing.SketchPlanColorVariant(spcv_id) NOT NULL,
	dt              DATETIME2(0) NOT NULL,
	employee_id     INT NOT NULL,
	is_deleted      BIT NOT NULL
)

GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_CoveredDetail_spcv_id] ON Planing.CoveringDetail(spcv_id) WHERE is_deleted = 0 ON [Indexes]
GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_CoveredDetail_covering_id_spcv_id] ON Planing.CoveringDetail(covering_id, spcv_id) ON [Indexes]