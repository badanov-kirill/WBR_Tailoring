CREATE TABLE [Planing].[SketchPrePlanStatus]
(
	spps_id         TINYINT CONSTRAINT [PK_SketchPrePlanStatus] PRIMARY KEY CLUSTERED NOT NULL,
	spps_name       VARCHAR(50) NOT NULL,
	dt              DATETIME2(0) NOT NULL,
	employee_id     INT NOT NULL
)
