CREATE TABLE [History].[SketchPlanColorVariantCost]
(
	log_id                  INT IDENTITY(1, 1) CONSTRAINT [PK_History_SketchPlanColorVariantCost] NOT NULL,
	spcv_id                 INT NOT NULL,
	pan_id                  INT NOT NULL,
	dt                      DATETIME2(0) NOT NULL,
	employee_id             INT NOT NULL,
	cost_rm                 DECIMAL(9, 2) NULL,
	cost_work               DECIMAL(9, 2) NULL,
	cost_fix                DECIMAL(9, 2) NULL,
	cost_add                DECIMAL(9, 2) NULL,
	price_ru                DECIMAL(9, 2) NULL,
	proc_id                 INT NOT NULL,
	cost_cutting            DECIMAL(9, 2) NULL,
	cost_rm_without_nds     DECIMAL(9, 2) NULL
)
