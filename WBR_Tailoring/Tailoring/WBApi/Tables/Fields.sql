CREATE TABLE [WBApi].[Fields]
(
	fields_id               INT IDENTITY(1, 1) CONSTRAINT [PK_WBApiFields] PRIMARY KEY CLUSTERED NOT NULL,
	fd_id                   INT CONSTRAINT [FK_Fields_fd_id] FOREIGN KEY REFERENCES WBApi.FieldsDict(fd_id) NOT NULL,
	fields_name             VARCHAR(200) NOT NULL,
	is_available            BIT NOT NULL,
	use_only_dict_value     BIT NOT NULL,
	max_cnt                 INT NULL,
	is_number               BIT NOT NULL,
	dt                      DATETIME2(0) NOT NULL
)

GO 
CREATE UNIQUE NONCLUSTERED INDEX [UQ_WBApiFields_fields_name_fd_id] ON WBApi.Fields(fields_name, fd_id) ON [Indexes]