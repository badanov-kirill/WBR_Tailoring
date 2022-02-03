CREATE TABLE [Ozon].[ArticleSaveTaskError]
(
	task_id        BIGINT CONSTRAINT [PK_ArticleSaveTaskError] PRIMARY KEY CLUSTERED NOT NULL,
	dt             DATETIME NOT NULL,
	error_text     VARCHAR(MAX) NOT NULL
)
