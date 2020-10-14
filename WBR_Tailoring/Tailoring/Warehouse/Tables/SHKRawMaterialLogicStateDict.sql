CREATE TABLE [Warehouse].[SHKRawMaterialLogicStateDict]
(
	state_id        INT CONSTRAINT [PK_SHKRawMaterialLogicStateDict] PRIMARY KEY CLUSTERED NOT NULL,
	state_name      VARCHAR(50) NOT NULL,
	state_descr     VARCHAR(500) NULL,
	dt              DATETIME2(0) NOT NULL,
	employee_id     INT NOT NULL
)

GO 

CREATE UNIQUE NONCLUSTERED INDEX [UQ_SHKRawMaterialStateLogicDict_state_name] ON Warehouse.SHKRawMaterialLogicStateDict(state_name) ON [Indexes]
