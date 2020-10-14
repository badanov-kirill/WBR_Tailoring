CREATE TABLE [Planing].[SketchPrePlan_TechnologicalSequence]
(
	sppts_id            INT IDENTITY(1, 1) CONSTRAINT [PK_SketchPrePlan_TechnologicalSequence] PRIMARY KEY CLUSTERED NOT NULL,
	spp_id              INT CONSTRAINT [FK_SketchPrePlan_TechnologicalSequence_spcv_id] FOREIGN KEY REFERENCES Planing.SketchPrePlan(spp_id) NOT NULL,
	operation_range     SMALLINT NOT NULL,
	ct_id               INT CONSTRAINT [FK_SketchPrePlan_TechnologicalSequence_ct_id] FOREIGN KEY REFERENCES Material.ClothType(ct_id) NOT NULL,
	ta_id               INT CONSTRAINT [FK_SketchPrePlan_TechnologicalSequence_ta_id] FOREIGN KEY REFERENCES Technology.TechAction(ta_id) NOT NULL,
	element_id          INT CONSTRAINT [FK_SketchPrePlan_TechnologicalSequence_element_id] FOREIGN KEY REFERENCES Technology.Element(element_id) NOT NULL,
	equipment_id        INT CONSTRAINT [FK_SketchPrePlan_TechnologicalSequence_equipment_id] FOREIGN KEY REFERENCES Technology.Equipment(equipment_id) NOT NULL,
	dr_id               TINYINT CONSTRAINT [FK_SketchPrePlan_TechnologicalSequence_dr_id] FOREIGN KEY REFERENCES Technology.DifficultyRebuffing(dr_id) NOT NULL,
	dc_id               TINYINT CONSTRAINT [FK_SketchPrePlan_TechnologicalSequence_dc_id] FOREIGN KEY REFERENCES Technology.DrawingComplexity(dc_id) NOT NULL,
	operation_value     DECIMAL(9, 3) NOT NULL,
	discharge_id        TINYINT CONSTRAINT [FK_SketchPrePlan_TechnologicalSequence_discharge_id] FOREIGN KEY REFERENCES Technology.Discharge(discharge_id) NOT NULL,
	rotaiting           DECIMAL(9, 5) NOT NULL,
	dc_coefficient      DECIMAL(9, 5) NOT NULL,
	employee_id         INT NOT NULL,
	dt                  DATETIME2(0) NOT NULL,
	operation_time      AS operation_value * rotaiting * dc_coefficient,
	comment_id          INT CONSTRAINT [FK_SketchPrePlan_TechnologicalSequence_comment_id] FOREIGN KEY REFERENCES Technology.CommentDict(comment_id) NOT NULL
)

GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_SketchPrePlan_TechnologicalSequence_sketch_id_operation_range] ON Planing.SketchPrePlan_TechnologicalSequence(spp_id, operation_range) 
ON [Indexes]

GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_SketchPrePlan_TechnologicalSequence_sketch_id_ta_id_element_id_equipment_id_operation_value_comment_id] ON Planing.SketchPrePlan_TechnologicalSequence(spp_id, ta_id, element_id, equipment_id, comment_id) 
ON [Indexes]   
