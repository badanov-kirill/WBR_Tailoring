CREATE TABLE [History].[ProdArticleSyncDataRequest]
(
	log_id           BIGINT IDENTITY(1, 1) CONSTRAINT [PK_History_ProdArticleSyncDataRequest] PRIMARY KEY CLUSTERED NOT NULL,
	dt               DATETIME2(0) NOT NULL,
	pa_id            INT NOT NULL,
	spec_uid         VARCHAR(36) NULL,
	data_request     VARCHAR(MAX) NOT NULL
)
