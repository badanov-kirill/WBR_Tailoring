CREATE TABLE [Warehouse].[SHKSpaceUnit]
(
	shksu_id               INT IDENTITY(1, 1) CONSTRAINT [PK_SHKSpaceUnit] PRIMARY KEY CLUSTERED NOT NULL,
	doc_id                 INT NULL,
	doc_type_id            TINYINT NULL CONSTRAINT [CH_SHKSpaceUnit_doc_type_id] CHECK(doc_type_id IS NULL OR doc_type_id = 1),
	su_id                  INT NULL CONSTRAINT [FK_SHKSpaceUnit_su_id] FOREIGN KEY REFERENCES RefBook.SpaceUnit(su_id),
	quantity               SMALLINT NULL,
	create_dt              DATETIME2(0) NOT NULL,
	create_employee_id     INT NOT NULL,
	close_dt               DATETIME2(0) NULL,
	close_employee_id      INT NULL,
	CONSTRAINT [FK_SHKSpaceUnit_doc_id_doc_type_id] FOREIGN KEY(doc_type_id, doc_id) REFERENCES Documents.DocumentID(doc_type_id, doc_id)
)
GO