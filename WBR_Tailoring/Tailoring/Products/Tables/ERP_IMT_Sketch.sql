CREATE TABLE [Products].[ERP_IMT_Sketch]
(
	imt_id          INT CONSTRAINT [PK_ERP_IMT_Sketch] PRIMARY KEY CLUSTERED NOT NULL,
	sketch_id       INT CONSTRAINT [FK_ERP_IMT_Sketch] FOREIGN KEY REFERENCES Products.Sketch(sketch_id) NOT NULL,
	sa              VARCHAR(36) NOT NULL,
	employee_id     INT NOT NULL,
	dt              DATETIME2(0) NOT NULL
)
