CREATE TABLE [Material].[RawMaterialInvoiceCorrectionType]
(
	rmict_id TINYINT CONSTRAINT [PK_RawMaterialInvoiceCorrectionType] PRIMARY KEY CLUSTERED NOT NULL,
	rmict_name VARCHAR(50) NOT NULL,
	dt DATETIME2(0) NOT NULL,
	employee_id INT NOT NULL
)
