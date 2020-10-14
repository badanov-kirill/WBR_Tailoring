CREATE TABLE [Technology].[EquipmentMapping]
(
	ct_id            INT CONSTRAINT [FK_EquipmentMapping_ct_id] FOREIGN KEY REFERENCES Material.ClothType(ct_id) NOT NULL,
	ta_id            INT CONSTRAINT [FK_EquipmentMapping_ta_id] FOREIGN KEY REFERENCES Technology.TechAction(ta_id) NOT NULL,
	equipment_id     INT CONSTRAINT [FK_EquipmentMapping_equipment_id] FOREIGN KEY REFERENCES Technology.Equipment(equipment_id) NOT NULL,
	discharge_id     TINYINT CONSTRAINT [FK_EquipmentMapping_discharge_id] FOREIGN KEY REFERENCES Technology.Discharge(discharge_id) NOT NULL,
	dt               DATETIME2(0) NOT NULL,
	employee_id      INT NOT NULL
	CONSTRAINT [PK_EquipmentMapping] PRIMARY KEY CLUSTERED(ct_id, ta_id, equipment_id)
)
