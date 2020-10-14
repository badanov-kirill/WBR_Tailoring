CREATE TABLE [Planing].[SketchPlanColorVariantCompletingComment]
(
	spcvc_id        INT CONSTRAINT [FK_SketchPlanColorVariantCompletingComment_spcvc_id] FOREIGN KEY REFERENCES Planing.SketchPlanColorVariantCompleting(spcvc_id) NOT 
	NULL,
	dt              DATETIME2(0) NOT NULL,
	employee_id     INT NOT NULL,
	comment         VARCHAR(300) NOT NULL,
	CONSTRAINT [PK_SketchPlanColorVariantCompletingComment] PRIMARY KEY CLUSTERED(spcvc_id, dt, employee_id)
)