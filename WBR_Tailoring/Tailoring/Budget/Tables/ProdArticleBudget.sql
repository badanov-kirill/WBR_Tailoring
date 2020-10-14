CREATE TABLE [Budget].[ProdArticleBudget]
(
	pab_id                  INT IDENTITY(1, 1) CONSTRAINT [PK_ProdArticleBudget] PRIMARY KEY CLUSTERED NOT NULL,
	pa_id                   INT CONSTRAINT [FK_ProdArticleBudget_pa_id] FOREIGN KEY REFERENCES Products.ProdArticle(pa_id) NOT NULL,
	plan_count              SMALLINT NOT NULL,
	plan_year               SMALLINT NULL,
	plan_month              TINYINT NULL,
	employee_id             INT NOT NULL,
	dt                      [dbo].[SECONDSTIME] NOT NULL,
	planing_employee_id     INT NOT NULL,
	planing_dt              [dbo].[SECONDSTIME] NOT NULL,
	approved_employee       INT NULL,
	approved_dt             [dbo].[SECONDSTIME] NULL,
	bs_id                   INT CONSTRAINT [FK_ProdArticleBudget_bs_id] FOREIGN KEY REFERENCES Budget.BudgetStatus(bs_id) NOT NULL,
	office_id               INT NULL,
	comment                 VARCHAR(500) NULL,
	rv                      ROWVERSION NOT NULL
)

GO

CREATE UNIQUE NONCLUSTERED INDEX [UQ_ProdArticleBudget_pa_id_plan_year_plan_month] ON Budget.ProdArticleBudget(pa_id, plan_year, plan_month) ON [Indexes]