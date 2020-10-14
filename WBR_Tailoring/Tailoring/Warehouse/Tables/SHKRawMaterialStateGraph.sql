CREATE TABLE [Warehouse].[SHKRawMaterialStateGraph]
(
	state_src_id     INT CONSTRAINT [FK_SHKRawMaterialStateGraph_state_src_id] FOREIGN KEY REFERENCES Warehouse.SHKRawMaterialStateDict(state_id) NOT NULL,
	state_dst_id     INT CONSTRAINT [FK_SHKRawMaterialStateGraph_state_dst_id] FOREIGN KEY REFERENCES Warehouse.SHKRawMaterialStateDict(state_id) NOT NULL,
	dt               dbo.SECONDSTIME NOT NULL,
	employee_id      INT NOT NULL,
	CONSTRAINT [PK_SHKRawMaterialStateGraph] PRIMARY KEY CLUSTERED(state_src_id, state_dst_id)
)