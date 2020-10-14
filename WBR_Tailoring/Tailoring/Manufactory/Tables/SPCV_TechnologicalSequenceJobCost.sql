CREATE TABLE [Manufactory].[SPCV_TechnologicalSequenceJobCost]
(
	office_id         INT CONSTRAINT [FK_SPCV_TechnologicalSequenceJobCost_office_id] FOREIGN KEY REFERENCES Settings.OfficeSetting(office_id) NOT NULL,
	discharge_id      TINYINT CONSTRAINT [FK_SPCV_TechnologicalSequenceJobCost_discharge_id] FOREIGN KEY REFERENCES Technology.Discharge(discharge_id) NOT NULL,
	cost_per_hour     DECIMAL(9, 2) NOT NULL,
	CONSTRAINT [PK_SPCV_TechnologicalSequenceJobCost] PRIMARY KEY CLUSTERED(office_id, discharge_id)
)
