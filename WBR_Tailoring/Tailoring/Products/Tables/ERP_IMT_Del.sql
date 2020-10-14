CREATE TABLE [Products].[ERP_IMT_Del]
(
	imt_id          INT CONSTRAINT [PK_ERP_IMT_Del] PRIMARY KEY CLUSTERED NOT NULL,
	employee_id     INT,
	dt              DATETIME2(0)
)
