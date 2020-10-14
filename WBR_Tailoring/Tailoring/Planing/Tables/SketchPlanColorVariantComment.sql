CREATE TABLE [Planing].[SketchPlanColorVariantComment]
(
	spcv_id         INT CONSTRAINT [FK_SketchPlanColorVariantComment_spcvc_id] FOREIGN KEY REFERENCES Planing.SketchPlanColorVariant(spcv_id) NOT 
	NULL,
	dt              DATETIME2(0) NOT NULL,
	employee_id     INT NOT NULL,
	ct_id           TINYINT CONSTRAINT [FK_SketchPlanColorVariantComment_ct_id] FOREIGN KEY REFERENCES RefBook.CommentType(ct_id) NOT NULL,
	comment         VARCHAR(300) NOT NULL,
	CONSTRAINT [PK_SketchPlanColorVariantComment] PRIMARY KEY CLUSTERED(spcv_id, dt, employee_id)
)
