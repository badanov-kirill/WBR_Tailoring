CREATE TABLE [Planing].[PlanStatusGroup]
(
	psg_id          TINYINT CONSTRAINT [PK_PlanStatusGroup] PRIMARY KEY CLUSTERED NOT NULL,
	psg_name        VARCHAR(50) NOT NULL,
	dt              DATETIME2(0) NOT NULL,
	employee_id     INT
)
