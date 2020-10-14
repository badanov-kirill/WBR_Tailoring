CREATE TABLE [Manufactory].[TaskLayoutDetail]
(
	tld_id          INT IDENTITY(1, 1) CONSTRAINT [PK_TaskLayoutDetail] PRIMARY KEY CLUSTERED NOT NULL,
	tl_id           INT CONSTRAINT [FK_TaskLayoutDetail_tl_id] FOREIGN KEY REFERENCES Manufactory.TaskLayout(tl_id) NOT NULL,
	layout_id       INT CONSTRAINT [FK_TaskLayoutDetail_layout_id] FOREIGN KEY REFERENCES Manufactory.Layout(layout_id) NOT NULL,
	dt              DATETIME2(0) NOT NULL,
	employee_id     INT NOT NULL,
)

GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_TaskLayoutDetail_tl_id_layout_id] ON Manufactory.TaskLayoutDetail(tl_id, layout_id) ON [Indexes]