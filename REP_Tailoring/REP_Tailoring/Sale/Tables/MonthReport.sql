CREATE TABLE [Sale].[MonthReport]
(
	realizationreport_id     INT NOT NULL,
	period_dt                DATE NOT NULL,
	dt                       DATETIME2(0) NOT NULL,
	create_dt                DATETIME2(0) NOT NULL,
	cnt_load                 INT NOT NULL,
	cnt_pacages              INT NOT NULL,
	dt_first_packages        DATETIME2(0) NOT NULL,
	dt_last_packages         DATETIME2(0) NOT NULL,
	period_to_dt			 DATE NULL,
	CONSTRAINT [PK_MonthReport] PRIMARY KEY CLUSTERED(realizationreport_id, period_dt)
)
