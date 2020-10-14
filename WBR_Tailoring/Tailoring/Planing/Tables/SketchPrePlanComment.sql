CREATE TABLE [Planing].[SketchPrePlanComment]
(
	spp_id          INT CONSTRAINT [FK_SketchPrePlanComment_spp_id] FOREIGN KEY REFERENCES Planing.SketchPrePlan(spp_id) NOT NULL,
	dt              DATETIME2(0) NOT NULL,
	employee_id     INT NOT NULL,
	comment         VARCHAR(300) NOT NULL,
	CONSTRAINT [PK_SketchPrePlanComment] PRIMARY KEY CLUSTERED(spp_id, dt, employee_id)
)
