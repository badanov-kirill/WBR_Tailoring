CREATE TABLE [Planing].[AddedSketchPlanMapping]
(
	aspm_id            INT IDENTITY(1, 1) CONSTRAINT [PK_AddedSketchPlanMapping] PRIMARY KEY CLUSTERED NOT NULL,
	base_spcv_id       INT CONSTRAINT [FK_AddedSketchPlanMapping_base_spcv_id] FOREIGN KEY REFERENCES Planing.SketchPlanColorVariant(spcv_id) NOT NULL,
	linked_spcv_id     INT CONSTRAINT [FK_AddedSketchPlanMapping_linked_spcv_id] FOREIGN KEY REFERENCES Planing.SketchPlanColorVariant(spcv_id) NOT NULL,
	dt                 DATETIME2(0) NOT NULL,
	employee_id        INT NOT NULL
)

GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_AddedSketchPlanMapping_base_spcv_id_linked_spcv_id] ON Planing.AddedSketchPlanMapping(base_spcv_id, linked_spcv_id) ON [Indexes]

GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_AddedSketchPlanMapping_linked_spcv_id] ON Planing.AddedSketchPlanMapping(linked_spcv_id) ON [Indexes]