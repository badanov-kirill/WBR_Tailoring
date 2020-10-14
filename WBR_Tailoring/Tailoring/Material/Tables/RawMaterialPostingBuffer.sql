CREATE TABLE [Material].[RawMaterialPostingBuffer]
(
	shkrm_id INT CONSTRAINT [FK_RawMaterialPostingBuffer_shkrm_id] FOREIGN KEY REFERENCES Warehouse.SHKRawMaterial(shkrm_id) NOT NULL,
	dt dbo.SECONDSTIME NOT NULL,
	employee_id INT NOT NULL,
	CONSTRAINT [PK_RawMaterialPostingBuffer] PRIMARY KEY CLUSTERED (shkrm_id)
)
