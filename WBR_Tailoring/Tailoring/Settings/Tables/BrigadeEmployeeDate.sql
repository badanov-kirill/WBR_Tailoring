CREATE TABLE [Settings].[BrigadeEmployeeDate]
(
	employee_id            INT NOT NULL,
	begin_dt               DATE CONSTRAINT [CH_BrigadeEmployeeDate_begin_dt] CHECK(DATEPART(day,begin_dt)=1) NOT NULL,
	brigade_id             INT CONSTRAINT [FK_BrigadeEmployeeDate_brigade_id] FOREIGN KEY REFERENCES Settings.Brigade(brigade_id) NULL,
	create_employee_id     INT NOT NULL,
	dt                     DATETIME2(0) NOT NULL,
	CONSTRAINT [PK_BrigadeEmployeeDate] PRIMARY KEY(employee_id, begin_dt)
)
