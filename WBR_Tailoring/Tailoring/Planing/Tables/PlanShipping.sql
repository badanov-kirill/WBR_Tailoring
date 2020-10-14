CREATE TABLE [Planing].[PlanShipping]
(
	ps_id                  INT IDENTITY(1, 1) CONSTRAINT [PK_PlanShipping] PRIMARY KEY CLUSTERED NOT NULL,
	employee_id            INT NOT NULL,
	dt                     DATETIME2(0) NOT NULL,
	src_office_id          INT CONSTRAINT [FK_PlanShipping_src_office_id] FOREIGN KEY REFERENCES Settings.OfficeSetting(office_id) NOT NULL,
	dst_office_id          INT CONSTRAINT [FK_PlanShipping_dst_office_id] FOREIGN KEY REFERENCES Settings.OfficeSetting(office_id) NOT NULL,
	plan_dt                DATE NOT NULL,
	close_dt               DATETIME2(0) NULL,
	close_employee_id      INT NULL,
	permissible_weight     DECIMAL(3, 1) NOT NULL,
	ttn_id                 INT CONSTRAINT [FK_PlanShipping_ttn_id] FOREIGN KEY REFERENCES Logistics.TTN(ttn_id) NULL
)

GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_PlanShipping] ON Planing.PlanShipping(ttn_id) WHERE ttn_id IS NOT NULL ON [Indexes]