CREATE TABLE [Planing].[SketchPlanColorVariantCounter]
(
	spcv_id           INT CONSTRAINT [FK_SketchPlanColorVariantCounter_spcv_id] FOREIGN KEY REFERENCES Planing.SketchPlanColorVariant(spcv_id) NOT NULL,
	cutting_qty       SMALLINT NOT NULL,
	cut_write_off     SMALLINT NOT NULL,
	write_off         SMALLINT NOT NULL,
	packaging         SMALLINT NOT NULL,
	finished          SMALLINT NOT NULL,
	dt_close          DATETIME2(0) NULL,
	CONSTRAINT [PK_SketchPlanColorVariantCounter] PRIMARY KEY CLUSTERED(spcv_id)
)