CREATE TABLE [Products].[ProdArticleSyncError]
(
	error_id       INT IDENTITY(1, 1) CONSTRAINT [PK_ProdArticleSyncError] PRIMARY KEY CLUSTERED NOT NULL,
	pass_id        TINYINT NOT NULL,
	pa_id          INT NOT NULL,
	spec_uid       VARCHAR(36) NULL,
	comment        VARCHAR(200) NULL,
	dt             DATETIME2(0) NOT NULL,
	data_send      VARCHAR(MAX),
	data_error     VARCHAR(MAX)
)