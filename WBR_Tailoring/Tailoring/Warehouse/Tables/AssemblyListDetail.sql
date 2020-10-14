CREATE TABLE [Warehouse].[AssemblyListDetail]
(
	ald_id          INT IDENTITY(1, 1) CONSTRAINT [PK_AssemblyListDetail] PRIMARY KEY CLUSTERED NOT NULL,
	al_id           INT CONSTRAINT [FK_AssemblyListDetail_al_id] FOREIGN KEY REFERENCES Warehouse.AssemblyList(al_id) NOT NULL,
	shkrm_id        INT CONSTRAINT [FK_AssemblyListDetail_shkrm_id] FOREIGN KEY REFERENCES Warehouse.SHKRawMaterial(shkrm_id) NOT NULL,
	employee_id     INT NOT NULL,
	dt              DATETIME2(0) NOT NULL,
	comment         VARCHAR(200) NULL
)

GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_AssemblyListDetail_al_id_shkrm_id] ON Warehouse.AssemblyListDetail(al_id, shkrm_id) ON [Indexes]
