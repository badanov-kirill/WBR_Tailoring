CREATE TABLE [History].[SketchPlanColorVariantCompleting]
(
	log_id                INT IDENTITY(1, 1) CONSTRAINT [PK_History_SketchPlanColorVariantCompleting] PRIMARY KEY CLUSTERED NOT NULL,
	spcvc_id              INT NOT NULL,
	spcv_id               INT NOT NULL,
	completing_id         INT NOT NULL,
	completing_number     TINYINT NOT NULL,
	rmt_id                INT NOT NULL,
	color_id              INT NOT NULL,
	frame_width           SMALLINT NULL,
	okei_id               INT NOT NULL,
	consumption           DECIMAL(9, 3) NULL,
	comment               VARCHAR(300) NULL,
	dt                    dbo.SECONDSTIME NOT NULL,
	employee_id           INT NOT NULL,
	cs_id                 TINYINT,
	proc_id               INT NOT NULL,
)
