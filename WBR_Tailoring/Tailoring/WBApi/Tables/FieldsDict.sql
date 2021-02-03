CREATE TABLE [WBApi].[FieldsDict]
(
	fd_id       INT IDENTITY(1, 1) CONSTRAINT [PK_WBApiFieldsDict] PRIMARY KEY CLUSTERED NOT NULL,
	fd_name     VARCHAR(100) NOT NULL,
	dt          DATETIME2(0)
)
GO 
CREATE UNIQUE NONCLUSTERED INDEX [UQ_WBApiFieldsDict_fd_name] ON  [WBApi].[FieldsDict] (fd_name) ON [Indexes]