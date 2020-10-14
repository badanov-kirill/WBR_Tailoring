CREATE TABLE [Synchro].[Upload_Covering_BuhVas]
(
	covering_id INT CONSTRAINT [PK_Upload_Covering_BuhVas] PRIMARY KEY CLUSTERED NOT NULL,
	rv ROWVERSION NOT NULL,
	dt DATETIME2(0) NOT NULL
)
