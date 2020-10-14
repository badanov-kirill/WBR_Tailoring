CREATE TABLE [Material].[RawMaterialTN]
(
	rmtn_id         INT IDENTITY(1, 1) CONSTRAINT [PK_RawMaterialTN] PRIMARY KEY CLUSTERED NOT NULL,
	doc_id          INT NOT NULL,
	doc_type_id     TINYINT NOT NULL,
	rmtn_name       VARCHAR(30) NOT NULL,
	rmtn_dt         DATE,
	dt              dbo.SECONDSTIME NOT NULL,
	employee_id     INT NOT NULL,
	is_deleted      BIT CONSTRAINT [DF_RawMaterialTN_is_deleted] DEFAULT(0) NOT NULL,
	CONSTRAINT [FK_RawMaterialTN_doc_id_doc_type_id] FOREIGN KEY(doc_type_id, doc_id) REFERENCES Documents.DocumentID(doc_type_id, doc_id),
	CONSTRAINT [CH_RawMaterialTN_doc_type_id] CHECK(doc_type_id = 1)
)

GO

CREATE UNIQUE NONCLUSTERED INDEX [UQ_RawMaterialTN_rmi_id_rmtn_name] ON Material.RawMaterialTN(doc_id, rmtn_name) ON [Indexes]