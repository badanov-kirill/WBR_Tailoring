CREATE TABLE [Planing].[PlantLoadingPlan]
(
	spcv_id                INT CONSTRAINT [FK_PlantLoadingPlan_spcv_id] FOREIGN KEY REFERENCES Planing.SketchPlanColorVariant(spcv_id) NOT NULL,
	create_employee_id     INT NOT NULL,
	create_dt              DATETIME2(0) NOT NULL,
	launch_dt              DATE NOT NULL,
	finish_dt              DATE NOT NULL,
	labor_costs            INT NOT NULL,
	office_id              INT CONSTRAINT [FK_PlantLoadingPlan_office_id] FOREIGN KEY REFERENCES Settings.OfficeSetting(office_id) NOT NULL,
	qty					   SMALLINT NOT NULL,
	CONSTRAINT [PK_PlantLoadingPlan] PRIMARY KEY CLUSTERED(spcv_id)
)
