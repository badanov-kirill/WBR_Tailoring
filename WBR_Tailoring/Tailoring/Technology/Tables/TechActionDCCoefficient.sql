CREATE TABLE [Technology].[TechActionDCCoefficient]
(
	ct_id              INT CONSTRAINT [FK_TechActionDCCoefficient_ct_id] FOREIGN KEY REFERENCES Material.ClothType(ct_id) NOT NULL,
	ta_id              INT CONSTRAINT [FK_TechActionDCCoefficient_ta_id] FOREIGN KEY REFERENCES Technology.TechAction(ta_id) NOT NULL,
	element_id         INT CONSTRAINT [FK_TechActionDCCoefficient_element_id] FOREIGN KEY REFERENCES Technology.Element(element_id) NOT NULL,
	equipment_id       INT CONSTRAINT [FK_TechActionDCCoefficient_equipment_id] FOREIGN KEY REFERENCES Technology.Equipment(equipment_id) NOT NULL,
	dc_id              TINYINT CONSTRAINT [FK_TechActionDCCoefficient_dc_id] FOREIGN KEY REFERENCES Technology.DrawingComplexity(dc_id) NOT NULL,
	dc_coefficient     DECIMAL(9, 5) NOT NULL,
	CONSTRAINT [PK_TechActionDCCoefficient] PRIMARY KEY CLUSTERED(ct_id, ta_id, element_id, equipment_id, dc_id)
)