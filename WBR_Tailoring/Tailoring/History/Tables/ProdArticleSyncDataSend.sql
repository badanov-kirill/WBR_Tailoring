CREATE TABLE [History].[ProdArticleSyncDataSend]
(
	log_id          BIGINT IDENTITY(1, 1) CONSTRAINT [PK_History_ProdArticleSyncDataSend] PRIMARY KEY CLUSTERED NOT NULL,
	dt              DATETIME2(0) NOT NULL,
	pa_id           INT NOT NULL,
	data_send       VARCHAR(MAX) NOT NULL,
	data_answer     VARCHAR(MAX) NULL,
	spec_uid        VARCHAR(36) NULL
)
