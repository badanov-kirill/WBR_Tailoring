CREATE TABLE [Planing].[SketchPlan]
(
	sp_id                  INT IDENTITY(1, 1) CONSTRAINT [PK_SketchPlan] PRIMARY KEY CLUSTERED NOT NULL,
	sketch_id              INT CONSTRAINT [FK_SketchPlan_sketch_id] FOREIGN KEY REFERENCES Products.Sketch(sketch_id) NOT NULL,
	ps_id                  TINYINT CONSTRAINT [FK_SketchPlan_ps_id] FOREIGN KEY REFERENCES Planing.PlanStatus(ps_id) NOT NULL,
	create_employee_id     INT NOT NULL,
	create_dt              dbo.SECONDSTIME NOT NULL,
	employee_id            INT NOT NULL,
	dt                     dbo.SECONDSTIME NOT NULL,
	comment                VARCHAR(200) NULL,
	plan_year              SMALLINT NULL,
	plan_month             TINYINT NULL,
	sew_office_id          INT CONSTRAINT [FK_SketchPlan_sew_office_id] FOREIGN KEY REFERENCES Settings.OfficeSetting(office_id) NULL,
	to_purchase_dt         DATETIME2(0) NULL,
	qp_id                  TINYINT CONSTRAINT [FK_SketchPlan_qp_id] FOREIGN KEY REFERENCES Products.QueuePriority(qp_id) NOT NULL,
	plan_qty               SMALLINT NULL,
	cv_qty                 TINYINT NULL,
	plan_sew_dt            DATE NULL,
	spp_id                 INT CONSTRAINT [FK_SketchPlan_spp_id] FOREIGN KEY REFERENCES Planing.SketchPrePlan(spp_id) NULL,
	season_local_id        INT CONSTRAINT [FK_SketchPlan_season_local_id] FOREIGN KEY REFERENCES Products.SeasonLocal(season_local_id) NULL,
	season_model_year      SMALLINT NULL,
	is_preorder			   BIT CONSTRAINT [DF_SketchPlan_is_preorder] DEFAULT (0) NOT NULL,
	supplier_id			   INT CONSTRAINT [FK_SketchPlan_supplier_id] FOREIGN KEY REFERENCES Suppliers.Supplier(supplier_id) NULL
)

GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_SketchPlan] ON Planing.SketchPlan(sketch_id) WHERE ps_id = 1 ON [Indexes]

GO
CREATE NONCLUSTERED INDEX [IX_SketchPlan_spp_id] ON Planing.SketchPlan(spp_id) WHERE spp_id IS NOT NULL ON [Indexes]