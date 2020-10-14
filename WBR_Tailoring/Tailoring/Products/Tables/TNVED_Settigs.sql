CREATE TABLE [Products].[TNVED_Settigs]
(
	ts_id               INT IDENTITY(1, 1) CONSTRAINT [PK_TNVED_Settigs] PRIMARY KEY CLUSTERED NOT NULL,
	subject_id          INT CONSTRAINT [FK_TNVED_Settigs_subject_id] FOREIGN KEY REFERENCES Products.[Subject](subject_id) NOT NULL,
	ct_id               INT CONSTRAINT [FK_TNVED_Settigs_ct_id] FOREIGN KEY REFERENCES Material.ClothType(ct_id) NOT NULL,
	consist_type_id     INT CONSTRAINT [FK_TNVED_Settigs_consist_type_id] FOREIGN KEY REFERENCES Products.ConsistType (consist_type_id) NOT NULL,
	tnved_id            INT CONSTRAINT [FK_TNVED_Settigs_tnved_id] FOREIGN KEY REFERENCES Products.TNVED(tnved_id) NOT NULL
)
GO

CREATE UNIQUE NONCLUSTERED INDEX [UQ_TNVED_Settigs_subject_id_ct_id_consist_type_id]
    ON Products.TNVED_Settigs(subject_id, ct_id, consist_type_id)
    ON [Indexes];
GO