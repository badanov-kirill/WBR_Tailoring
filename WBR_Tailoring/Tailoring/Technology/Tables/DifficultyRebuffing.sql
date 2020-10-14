CREATE TABLE [Technology].[DifficultyRebuffing]
(
	dr_id           TINYINT CONSTRAINT [PK_DifficultyRebuffing] PRIMARY KEY CLUSTERED NOT NULL,
	dr_name         VARCHAR(50) NOT NULL,
	dt              DATETIME2(0) NOT NULL,
	employee_id     INT NOT NULL
)
