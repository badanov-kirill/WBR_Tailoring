CREATE TABLE [Products].[Sertificates]
(
	sertificate_id       INT IDENTITY(1, 1) CONSTRAINT [PK_Sertificates] PRIMARY KEY CLUSTERED NOT NULL,
	sertificate_type     CHAR(1) NOT NULL,
	sertificate_num      VARCHAR(50) NOT NULL,
	sertificate_dt       DATE NOT NULL,
	finish_dt            DATE NOT NULL
)
