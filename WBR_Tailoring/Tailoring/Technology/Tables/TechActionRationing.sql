CREATE TABLE [Technology].[TechActionRationing]
(
	ct_id              INT CONSTRAINT [FK_TechActionRationing_ct_id] FOREIGN KEY REFERENCES Material.ClothType(ct_id) NOT NULL,
	ta_id              INT CONSTRAINT [FK_TechActionRationing_ta_id] FOREIGN KEY REFERENCES Technology.TechAction(ta_id) NOT NULL,
	element_id         INT CONSTRAINT [FK_TechActionRationing_element_id] FOREIGN KEY REFERENCES Technology.Element(element_id) NOT NULL,
	equipment_id       INT CONSTRAINT [FK_TechActionRationing_equipment_id] FOREIGN KEY REFERENCES Technology.Equipment(equipment_id) NOT NULL,
	dr_id              TINYINT CONSTRAINT [FK_TechActionRationing_dr_id] FOREIGN KEY REFERENCES Technology.DifficultyRebuffing(dr_id) NOT NULL,
	rotaiting          DECIMAL(9, 5) NOT NULL,
	CONSTRAINT [PK_TechActionRationing] PRIMARY KEY CLUSTERED(ct_id, ta_id, element_id, equipment_id, dr_id)
)
