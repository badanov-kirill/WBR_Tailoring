CREATE TABLE [Budget].[PreBudgetSketch]
(
	pbs_id                 INT IDENTITY(1, 1) CONSTRAINT [PK_PreBudgetSketch] PRIMARY KEY CLUSTERED NOT NULL,
	sketch_id               INT CONSTRAINT [FK_PreBudgetSketch_sketch_id] FOREIGN KEY REFERENCES Products.Sketch (sketch_id) NOT NULL,
	plan_qty                SMALLINT NULL,
	plan_year               SMALLINT NOT NULL,
	plan_month              TINYINT NOT NULL,
	planing_employee_id     INT NOT NULL,
	planing_dt              dbo.SECONDSTIME NOT NULL,
	employee_id             INT NOT NULL,
	dt                      dbo.SECONDSTIME NOT NULL,
	office_id               INT NULL
)
    
GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_PreBudgetSketch] ON Budget.PreBudgetSketch(sketch_id, plan_year, plan_month) ON [Indexes]