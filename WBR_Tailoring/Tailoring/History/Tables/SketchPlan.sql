CREATE TABLE [History].[SketchPlan]
(
	hsp_id          INT IDENTITY(1, 1) CONSTRAINT [PK_History_SketchPlan] PRIMARY KEY CLUSTERED NOT NULL,
	sp_id           INT NOT NULL,
	sketch_id       INT NOT NULL,
	ps_id           TINYINT NOT NULL,
	employee_id     INT NOT NULL,
	dt              dbo.SECONDSTIME NOT NULL,
	comment         VARCHAR(200) NULL
)
