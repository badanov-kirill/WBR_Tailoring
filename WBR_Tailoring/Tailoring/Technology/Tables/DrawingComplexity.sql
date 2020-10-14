CREATE TABLE [Technology].[DrawingComplexity]
(
	dc_id           TINYINT CONSTRAINT [PK_DrawingComplexity] PRIMARY KEY CLUSTERED NOT NULL,
	dc_name         VARCHAR(50) NOT NULL,
	dt              DATETIME2(0) NOT NULL,
	employee_id     INT NOT NULL
)
