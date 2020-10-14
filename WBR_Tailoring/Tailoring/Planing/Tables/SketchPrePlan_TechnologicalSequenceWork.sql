CREATE TABLE [Planing].[SketchPrePlan_TechnologicalSequenceWork]
(
	sppts_id      INT CONSTRAINT [FK_SketchPrePlan_TechnologicalSequenceWork_sppts_id] FOREIGN KEY REFERENCES Planing.SketchPrePlan_TechnologicalSequence(sppts_id) 
	NOT NULL,
	work_dt       DATE NOT NULL,
	office_id	  INT NOT NULL,
	work_time     INT NOT NULL,
	CONSTRAINT [PK_SketchPrePlan_TechnologicalSequenceWork] PRIMARY KEY CLUSTERED(sppts_id, work_dt)
)

GO
CREATE NONCLUSTERED INDEX [IX_SketchPrePlan_TechnologicalSequenceWork_work_dt] ON Planing.SketchPrePlan_TechnologicalSequenceWork(work_dt) INCLUDE(sppts_id, work_time) 
ON [Indexes]