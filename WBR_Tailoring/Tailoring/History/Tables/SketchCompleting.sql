CREATE TABLE [History].[SketchCompleting]
(
	hsc_id                INT IDENTITY(1, 1) CONSTRAINT [PK_History_SketchCompleting] PRIMARY KEY CLUSTERED NOT NULL,
	sc_id                 INT NOT NULL,
	sketch_id             INT NOT NULL,
	completing_id         INT NOT NULL,
	completing_number     TINYINT NOT NULL,
	frame_width           SMALLINT NULL,
	okei_id               INT NOT NULL,
	consumption           DECIMAL(9, 3) NULL,
	comment               VARCHAR(200) NULL,
	is_deleted            BIT NOT NULL,
	dt                    dbo.SECONDSTIME NOT NULL,
	employee_id           INT NOT NULL,
	base_rmt_id           INT NOT NULL
)
