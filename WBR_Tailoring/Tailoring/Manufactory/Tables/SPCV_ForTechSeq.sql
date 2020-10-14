CREATE TABLE [Manufactory].[SPCV_ForTechSeq]
(
	spcvfts_id                     INT IDENTITY(1, 1) CONSTRAINT [PK_SPCV_ForTechSeq] PRIMARY KEY CLUSTERED NOT NULL,
	spcv_id                        INT CONSTRAINT [FK_SPCV_ForTechSeq_spcv_id] FOREIGN KEY REFERENCES Planing.SketchPlanColorVariant(spcv_id) NOT NULL,
	create_dt                      DATETIME2(0) NOT NULL,
	qp_id                          TINYINT CONSTRAINT [FK_SPCV_ForTechSeq_qp_id] FOREIGN KEY REFERENCES Products.QueuePriority(qp_id) NOT NULL,
	base_technolog_employee_id     INT NULL,
	plan_dt                        DATE NULL,
	employee_id                    INT NULL,
	start_dt                       DATETIME2(0) NULL,
	finish_dt                      DATETIME2(0) NULL,
	proirity_level				   TINYINT CONSTRAINT [DF_SPCV_ForTechSeq_priority_level] DEFAULT (0) NOT NULL
)

GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_SPCV_ForTechSeq_spcv_id_start_dt] ON Manufactory.SPCV_ForTechSeq(spcv_id) WHERE start_dt IS NULL ON [Indexes]

GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_SPCV_ForTechSeq_employee_id_start_dt] ON Manufactory.SPCV_ForTechSeq(employee_id) WHERE finish_dt IS NULL AND employee_id IS NOT NULL ON [Indexes]