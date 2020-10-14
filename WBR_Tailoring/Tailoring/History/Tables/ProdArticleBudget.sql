CREATE TABLE [History].[ProdArticleBudget]
(
	hpab_id                 INT IDENTITY(1, 1) CONSTRAINT [PK_History_ProdArticleBudget] PRIMARY KEY CLUSTERED NOT NULL,
	pab_id                  INT NOT NULL,
	pa_id                   INT NOT NULL,
	plan_count              SMALLINT NOT NULL,
	plan_year               SMALLINT NULL,
	plan_month              TINYINT NULL,
	employee_id             INT NOT NULL,
	dt                      [dbo].[SECONDSTIME] NOT NULL,
	planing_employee_id     INT NOT NULL,
	planing_dt              [dbo].[SECONDSTIME] NOT NULL,
	approved_employee       INT NULL,
	approved_dt             [dbo].[SECONDSTIME] NULL,
	bs_id                   INT NOT NULL,
	office_id               INT NULL,
	comment                 VARCHAR(500) NULL
)