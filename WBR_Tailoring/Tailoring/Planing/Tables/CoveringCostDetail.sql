CREATE TABLE [Planing].[CoveringCostDetail]
(
	ccd_id             INT IDENTITY(1, 1) CONSTRAINT [PK_CoveringCostDetail] PRIMARY KEY CLUSTERED NOT NULL,
	covering_id        INT CONSTRAINT [FK_CoveringCostDetail_covering_id] FOREIGN KEY REFERENCES Planing.Covering(covering_id) NOT NULL,
	sketch_id          INT CONSTRAINT [FK_CoveringCostDetail_sketch_id] FOREIGN KEY REFERENCES Products.Sketch(sketch_id) NOT NULL,
	cutting_cnt        SMALLINT NOT NULL,
	amount_rm          DECIMAL(9, 2) NOT NULL,
	dt                 DATETIME2(0) NOT NULL,
	employee_id        INT NOT NULL,
	amount_cutting     DECIMAL(9, 2) NOT NULL
)

GO 
CREATE UNIQUE NONCLUSTERED INDEX [UQ_CoveringCostDetail] ON Planing.CoveringCostDetail(covering_id, sketch_id) ON [Indexes]