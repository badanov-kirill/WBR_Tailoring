CREATE TABLE [Manufactory].[WorkshopEquipment]
(
	we_id            INT IDENTITY(1, 1) CONSTRAINT [PK_WorkshopEquipment] PRIMARY KEY CLUSTERED NOT NULL,
	equipment_id     INT CONSTRAINT [FK_WorkshopEquipment_equipment_id] FOREIGN KEY REFERENCES Technology.Equipment(equipment_id) NOT NULL,
	article          VARCHAR(15) NULL,
	serial_num       VARCHAR(50) NULL,
	stuff_shk_id     INT NULL,
	comment          VARCHAR(200) NULL,
	zor_id           INT CONSTRAINT [FK_WorkshopEquipment_zor_id] FOREIGN KEY REFERENCES Warehouse.ZoneOfResponse(zor_id) NOT NULL,
	dt               DATETIME2(0) NOT NULL,
	employee_id      INT NOT NULL,
	is_deleted       BIT NOT NULL,
	work_hour        DECIMAL(3,1) NULL
)
