CREATE TABLE [Planing].[PlantLoadingPlan_TechnologicalSequenceWork]
(
	plpts_id        INT CONSTRAINT [FK_PlantLoadingPlan_TechnologicalSequenceWork_plpts_id] FOREIGN KEY REFERENCES Planing.PlantLoadingPlan_TechnologicalSequence(plpts_id) 
	NOT NULL,
	work_dt         DATE NOT NULL,
	employee_id     INT NOT NULL,
	office_id       INT CONSTRAINT [FK_PlantLoadingPlan_TechnologicalSequenceWork_office_id] FOREIGN KEY REFERENCES Settings.OfficeSetting(office_id) NOT NULL,
	work_time       INT NOT NULL,	
	CONSTRAINT [PK_PlantLoadingPlan_TechnologicalSequenceWork] PRIMARY KEY CLUSTERED(plpts_id, work_dt, employee_id, office_id)
)

GO
CREATE NONCLUSTERED INDEX [IX_PlantLoadingPlan_TechnologicalSequenceWork_work_dt] ON Planing.PlantLoadingPlan_TechnologicalSequenceWork(work_dt) INCLUDE(plpts_id, employee_id, work_time, office_id) 
ON [Indexes]