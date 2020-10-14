CREATE TABLE [Manufactory].[LayoutTS]
(
	lts_id             INT IDENTITY(1, 1) CONSTRAINT [PK_LayoutTS] PRIMARY KEY CLUSTERED NOT NULL,
	layout_id          INT CONSTRAINT [FK_LayoutTS_layout_id] FOREIGN KEY REFERENCES Manufactory.Layout(layout_id) NOT NULL,
	ts_id              INT CONSTRAINT [FK_LayoutTS_ts_id] FOREIGN KEY REFERENCES Products.TechSize(ts_id) NOT NULL,
	completing_qty     DECIMAL(9, 3) NOT NULL,
	dt                 DATETIME2(0) NOT NULL,
	employee_id        INT NOT NULL
)

GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_LayoutTS_layiut_id_ts_id] ON Manufactory.LayoutTS(layout_id, ts_id) ON [Indexes]