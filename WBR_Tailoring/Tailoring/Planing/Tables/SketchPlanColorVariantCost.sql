CREATE TABLE [Planing].[SketchPlanColorVariantCost]
(
	spcv_id                 INT CONSTRAINT [FK_SketchPlanColorVariantCost_spcv_id] FOREIGN KEY REFERENCES Planing.SketchPlanColorVariant(spcv_id) NOT NULL,
	pan_id                  INT CONSTRAINT [FK_SketchPlanColorVariantCost] FOREIGN KEY REFERENCES Products.ProdArticleNomenclature(pan_id) NOT NULL,
	dt                      DATETIME2(0) NOT NULL,
	employee_id             INT NOT NULL,
	cost_rm                 DECIMAL(9, 2) NOT NULL,
	cost_work               DECIMAL(9, 2) NOT NULL,
	cost_fix                DECIMAL(9, 2) NOT NULL,
	cost_add                DECIMAL(9, 2) NOT NULL,
	price_ru                DECIMAL(9, 2) NOT NULL,
	cost_cutting            DECIMAL(9, 2) NOT NULL,
	cost_rm_without_nds     DECIMAL(9, 2) NOT NULL,
	create_dt				DATE NOT NULL
	CONSTRAINT [PK_SketchPlanColorVariantCost] PRIMARY KEY CLUSTERED(spcv_id)
)
