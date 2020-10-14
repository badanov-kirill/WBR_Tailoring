CREATE TABLE [Settings].[EmployeeEquipment]
(
	employee_id      INT CONSTRAINT [FK_EmployeeEquipment_employee_id] FOREIGN KEY REFERENCES Settings.EmployeeSetting(employee_id) NOT NULL,
	equipment_id     INT CONSTRAINT [FK_EmployeeEquipment_equipment_id] FOREIGN KEY REFERENCES Technology.Equipment(equipment_id) NOT NULL,
	CONSTRAINT [PK_EmployeeEquipment] PRIMARY KEY CLUSTERED(employee_id, equipment_id)
)
