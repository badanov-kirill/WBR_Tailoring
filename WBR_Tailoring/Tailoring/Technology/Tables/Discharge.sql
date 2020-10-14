CREATE TABLE [Technology].[Discharge]
(
	discharge_id     TINYINT CONSTRAINT [PK_Discharge] PRIMARY KEY CLUSTERED NOT NULL,
	dt               DATETIME2(0) NOT NULL,
	employee_id      INT NOT NULL
)
