CREATE TABLE [Products].[SketchTechnologyJob]
(
	stj_id                 INT IDENTITY(1, 1) CONSTRAINT [PK_SketchTechnologyJob] PRIMARY KEY CLUSTERED NOT NULL,
	sketch_id              INT CONSTRAINT [FK_SketchTechnologyJob_sketch_id] FOREIGN KEY REFERENCES Products.Sketch(sketch_id) NOT NULL,
	create_dt              DATETIME2(0) NOT NULL,
	create_employee_id     INT NOT NULL,
	begin_dt               DATETIME2(0) NULL,
	begin_employee_id      INT NULL,
	end_dt                 DATETIME2(0) NULL,
	qp_id                  TINYINT CONSTRAINT [FK_SketchTechnologyJob_qp_id] FOREIGN KEY REFERENCES Products.QueuePriority(qp_id) NOT NULL,
	stjt_id TINYINT CONSTRAINT [DF_SketchTechnologyJob_stjt_id] DEFAULT(1) NOT NULL,
	CONSTRAINT [FK_SketchTechnologyJob_stjt_id] FOREIGN KEY(stjt_id) REFERENCES Products.SketchTechnologyJobType(stjt_id)
)

GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_SketchTechnologyJob_sketch_id_in_work] ON Products.SketchTechnologyJob(sketch_id) WHERE end_dt IS NULL ON [Indexes]
GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_SketchTechnologyJob_begin_employee_id_in_work] ON Products.SketchTechnologyJob(begin_employee_id) WHERE end_dt IS NULL AND 
begin_employee_id IS NOT NULL ON [Indexes]