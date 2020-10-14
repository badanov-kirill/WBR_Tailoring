CREATE TABLE [Planing].[SketchPrePlan]
(
	spp_id                   INT IDENTITY(1, 1) CONSTRAINT [PK_SketchPrePlan] PRIMARY KEY CLUSTERED NOT NULL,
	season_model_year        SMALLINT NOT NULL,
	season_local_id          INT CONSTRAINT [FK_SketchPrePlan_season_local_id] FOREIGN KEY REFERENCES Products.SeasonLocal(season_local_id) NOT NULL,
	sketch_id                INT CONSTRAINT [FK_SketchPrePlan_sketch_id] FOREIGN KEY REFERENCES Products.Sketch(sketch_id) NOT NULL,
	spps_id                  TINYINT CONSTRAINT [FK_SketchPrePlan_spps_id] FOREIGN KEY REFERENCES Planing.SketchPrePlanStatus(spps_id) NOT NULL,
	create_employee_id       INT NOT NULL,
	create_dt                DATETIME2(0) NOT NULL,
	employee_id              INT NOT NULL,
	dt                       DATETIME2(0) NOT NULL,
	sale_plan_dt             DATE NULL,
	plan_dt                  DATE NULL,
	buy_material_plan_dt     DATE NULL,
	sew_office_id            INT CONSTRAINT [FK_SketchPrePlan_sew_office_id] FOREIGN KEY REFERENCES Settings.OfficeSetting(office_id) NULL,
	plan_qty                 SMALLINT NULL,
	cv_qty                   TINYINT NULL
)

GO
CREATE NONCLUSTERED INDEX [IX_SketchPrePlan_season_model_year_season_local_id_sketch_id] ON Planing.SketchPrePlan(season_model_year, season_local_id, sketch_id) ON [Indexes]

GO
CREATE NONCLUSTERED INDEX [IX_SketchPrePlan_plan_dt] ON Planing.SketchPrePlan(plan_dt) ON [Indexes]