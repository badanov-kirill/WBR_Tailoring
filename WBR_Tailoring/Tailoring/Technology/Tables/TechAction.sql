CREATE TABLE [Technology].[TechAction]
(
	ta_id           INT IDENTITY(1, 1) CONSTRAINT [PK_TechAction] PRIMARY KEY CLUSTERED NOT NULL,
	ta_name         VARCHAR(50) NOT NULL,
	dt              DATETIME2(0) NOT NULL,
	employee_id     INT NOT NULL,
	is_deleted      BIT NOT NULL
)

GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_TechAction_ta_name] ON Technology.TechAction(ta_name) WHERE is_deleted = 0 ON [Indexes]