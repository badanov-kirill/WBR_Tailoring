CREATE TABLE [Planing].[SketchPlanColorVariantTSCounter]
(
	spcvts_id         INT CONSTRAINT [FK_SketchPlanColorVariantCounter_spcvts_id] FOREIGN KEY REFERENCES Planing.SketchPlanColorVariantTS(spcvts_id) NOT NULL,
	cutting_qty       SMALLINT NOT NULL,
	cut_write_off     SMALLINT NOT NULL,
	write_off         SMALLINT NOT NULL,
	packaging         SMALLINT NOT NULL,
	finished          SMALLINT NOT NULL,
	CONSTRAINT [PK_SketchPlanColorVariantTSCounter] PRIMARY KEY CLUSTERED(spcvts_id)
)
