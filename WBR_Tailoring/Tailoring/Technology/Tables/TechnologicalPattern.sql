CREATE TABLE [Technology].[TechnologicalPattern]
(
	tp_id                  INT IDENTITY(1, 1) CONSTRAINT [PK_TechnologicalPattern] PRIMARY KEY CLUSTERED NOT NULL,
	tp_name                VARCHAR(50) NOT NULL,
	ct_id                  INT CONSTRAINT [FK_TechnologicalPattern_ct_id] FOREIGN KEY REFERENCES Material.ClothType(ct_id) NOT NULL,
	is_deleted             BIT NOT NULL,
	create_employee_id     INT NOT NULL,
	employee_id            INT NOT NULL,
	dt                     DATETIME2(0) NOT NULL
)

GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_TechnologicalPattern_tp_name] ON Technology.TechnologicalPattern(tp_name) WHERE is_deleted = 0 ON [Indexes]