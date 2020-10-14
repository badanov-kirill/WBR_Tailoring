CREATE TABLE [Planing].[PlanStatus]
(
	ps_id           TINYINT CONSTRAINT [PK_PlanStatus] PRIMARY KEY CLUSTERED NOT NULL,
	ps_name         VARCHAR(50) NOT NULL,
	dt              dbo.SECONDSTIME NOT NULL,
	employee_id     INT NOT NULL,
	psg_id          TINYINT CONSTRAINT [FK_PlanStatus_psg_id] FOREIGN KEY REFERENCES Planing.PlanStatusGroup(psg_id) NOT NULL
)
