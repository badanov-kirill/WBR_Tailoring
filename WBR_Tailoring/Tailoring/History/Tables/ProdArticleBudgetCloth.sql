CREATE TABLE [History].[ProdArticleBudgetCloth]
(
	hpabc_id                 INT IDENTITY(1, 1) CONSTRAINT [PK_History_ProdArticleBudgetCloth] PRIMARY KEY CLUSTERED NOT NULL,
	pabc_id                  INT NOT NULL,
	pab_id                   INT NOT NULL,
	cloth_id                 INT NOT NULL,
	color_id                 INT NOT NULL,
	prev_count_meters        SMALLINT NOT NULL,
	ordered_count_meters     SMALLINT NULL,
	actual_count_meters      SMALLINT NULL,
	dt                       dbo.SECONDSTIME NOT NULL,
	bcs_id                   INT NOT NULL,
	employee_id              INT NOT NULL,
	comment                  VARCHAR(200) NULL,
	variant                  TINYINT NULL,
	is_main_color            BIT NULL
)
