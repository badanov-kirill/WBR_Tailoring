CREATE TABLE [Warehouse].[SHKRawMaterialLogicState]
(
	shkrm_id        INT CONSTRAINT [FK_SHKRawMaterialLogicState_shkrm_id] FOREIGN KEY REFERENCES Warehouse.SHKRawMaterial(shkrm_id) NOT NULL,
	state_id        INT CONSTRAINT [FK_SHKRawMaterialLogicState_state_id] FOREIGN KEY REFERENCES Warehouse.SHKRawMaterialLogicStateDict(state_id) NOT NULL,
	dt              dbo.SECONDSTIME NOT NULL,
	employee_id     INT NOT NULL,
	rv              ROWVERSION NOT NULL,
	CONSTRAINT [PK_SHKRawMaterialLogicState] PRIMARY KEY CLUSTERED(shkrm_id ASC)
)
