CREATE TABLE [RefBook].[FileExt]
(
	file_ext_id       SMALLINT IDENTITY(1, 1) CONSTRAINT [PK_FileExt] PRIMARY KEY CLUSTERED NOT NULL,
	file_ext_name     VARCHAR(20) NOT NULL
)

GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_FileExt_name] ON [RefBook].[FileExt] (file_ext_name) ON [Indexes]