CREATE TABLE [Technology].[TechnologicalPatternSequence]
(
	tps_is              INT IDENTITY(1, 1) CONSTRAINT [PK_TechnologicalPatternSequence] PRIMARY KEY CLUSTERED NOT NULL,
	tp_id               INT CONSTRAINT [FK_TechnologicalPatternSequence_tp_id] FOREIGN KEY REFERENCES Technology.TechnologicalPattern(tp_id) NOT NULL,
	operation_range     SMALLINT NOT NULL,
	ct_id               INT CONSTRAINT [FK_TechnologicalPatternSequence_ct_id] FOREIGN KEY REFERENCES Material.ClothType(ct_id) NOT NULL,
	ta_id               INT CONSTRAINT [FK_TechnologicalPatternSequence_ta_id] FOREIGN KEY REFERENCES Technology.TechAction(ta_id) NOT NULL,
	element_id          INT CONSTRAINT [FK_TechnologicalPatternSequence_element_id] FOREIGN KEY REFERENCES Technology.Element(element_id) NOT NULL,
	equipment_id        INT CONSTRAINT [FK_TechnologicalPatternSequence_equipment_id] FOREIGN KEY REFERENCES Technology.Equipment(equipment_id) NOT NULL,
	dr_id               TINYINT CONSTRAINT [FK_TechnologicalPatternSequence_dr_id] FOREIGN KEY REFERENCES Technology.DifficultyRebuffing(dr_id) NOT NULL,
	dc_id               TINYINT CONSTRAINT [FK_TechnologicalPatternSequence_dc_id] FOREIGN KEY REFERENCES Technology.DrawingComplexity(dc_id) NOT NULL,
	operation_value     DECIMAL(9, 3) NOT NULL,
	discharge_id        TINYINT CONSTRAINT [FK_TechnologicalPatternSequence_discharge_id] FOREIGN KEY REFERENCES Technology.Discharge(discharge_id) NOT NULL,
	rotaiting           DECIMAL(9, 5) NOT NULL,
	dc_coefficient      DECIMAL(9, 5) NOT NULL,
	comment             VARCHAR(100) NULL,
	employee_id         INT NOT NULL,
	dt                  DATETIME2(0) NOT NULL,
	operation_time      AS operation_value * rotaiting * dc_coefficient PERSISTED
)

GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_TechnologicalPatternSequence_tp_id_operation_range] ON Technology.TechnologicalPatternSequence(tp_id, operation_range) ON 
[Indexes]