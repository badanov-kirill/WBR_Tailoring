CREATE TABLE [Products].[Sertificates_TNVD]
(
	st_id              INT IDENTITY(1, 1) CONSTRAINT [PK_Sertificates_TNVD] PRIMARY KEY CLUSTERED NOT NULL,
	sertificate_id     INT CONSTRAINT [FK_Sertificates_sertificate_id] FOREIGN KEY REFERENCES Products.Sertificates(sertificate_id) NOT NULL,
	tnvd_cod           CHAR(4) NOT NULL
)

GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_Sertificates_TNVD_sertificate_id_tnvd_cod] ON Products.Sertificates_TNVD(sertificate_id, tnvd_cod) ON [Indexes]