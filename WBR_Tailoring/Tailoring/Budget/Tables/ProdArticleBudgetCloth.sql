CREATE TABLE [Budget].[ProdArticleBudgetCloth]
(
	pabc_id                  INT IDENTITY(1, 1) CONSTRAINT [PK_ProdArticleBudgetCloth] PRIMARY KEY CLUSTERED NOT NULL,
	pab_id                   INT CONSTRAINT [FK_ProdArticleBudgetCloth_pab_id] FOREIGN KEY REFERENCES Budget.ProdArticleBudget(pab_id) NOT NULL,
	cloth_id                 INT CONSTRAINT [FK_ProdArticleBudgetCloth_cloth_id] FOREIGN KEY REFERENCES Material.Cloth(cloth_id) NOT NULL,
	color_id                 INT CONSTRAINT [FK_ProdArticleBudgetCloth_color_id] FOREIGN KEY REFERENCES Material.ClothColor(color_id) NOT NULL,
	prev_count_meters        SMALLINT NOT NULL,
	ordered_count_meters     SMALLINT NULL,
	actual_count_meters      SMALLINT NULL,
	dt                       dbo.SECONDSTIME NOT NULL,
	bcs_id                   INT CONSTRAINT [FK_ProdArticleBudgetCloth_bcs_id] FOREIGN KEY REFERENCES Budget.BudgetClothStatus(bcs_id) NOT NULL,
	employee_id              INT NOT NULL,
	comment                  VARCHAR(200) NULL,
	rv                       ROWVERSION NOT NULL,
	variant                  TINYINT NULL,
	is_main_color            BIT NULL
)

GO

CREATE UNIQUE NONCLUSTERED INDEX [UQ_ProdArticleBudgetCloth_pab_id_cc_id] ON Budget.ProdArticleBudgetCloth(pab_id, cloth_id, color_id) ON [Indexes]

GO

CREATE UNIQUE NONCLUSTERED INDEX [UQ_ProdArticleBudgetCloth_pab_id_color_id] ON Budget.ProdArticleBudgetCloth(pab_id, color_id) WHERE is_main_color = 1 ON 
[Indexes]

GO

CREATE UNIQUE NONCLUSTERED INDEX [UQ_ProdArticleBudgetCloth_pab_id_variant] ON Budget.ProdArticleBudgetCloth(pab_id, variant) WHERE is_main_color = 1 ON 
[Indexes]

