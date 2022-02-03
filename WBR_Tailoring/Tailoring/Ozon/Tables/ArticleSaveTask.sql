CREATE TABLE [Ozon].[ArticleSaveTask]
(
	task_id BIGINT CONSTRAINT [PK_ArticleSaveTask] PRIMARY KEY CLUSTERED NOT NULL,
	dt           DATETIME2(0) NOT NULL,
	dt_save      DATETIME2(0) NOT NULL,
	dt_load      DATETIME2(0) NULL
)
