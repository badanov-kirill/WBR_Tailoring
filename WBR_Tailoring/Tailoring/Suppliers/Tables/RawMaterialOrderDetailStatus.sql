CREATE TABLE [Suppliers].[RawMaterialOrderDetailStatus]
(
	rmods_id        TINYINT CONSTRAINT [PK_RawMaterialOrderDetailStatus] PRIMARY KEY CLUSTERED NOT NULL,
	rmods_name      VARCHAR(50) NOT NULL,
	employee_id     INT NOT NULL,
	dt              DATETIME2(0) NOT NULL
)
