CREATE TABLE [Technology].[Equipment]
(
	equipment_id       INT IDENTITY(1, 1) CONSTRAINT [PK_Equipment] PRIMARY KEY CLUSTERED NOT NULL,
	equipment_name     VARCHAR(50) NOT NULL,
	dt                 DATETIME2(0) NOT NULL,
	employee_id        INT NOT NULL,
	is_deleted         BIT NOT NULL
)

GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_Equipment_equipment_name] ON Technology.Equipment(equipment_name) WHERE is_deleted = 0 ON [Indexes]
