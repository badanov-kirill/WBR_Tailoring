CREATE TABLE [Material].[RawMaterialInvoiceItem]
(
	rmii_id         INT NOT NULL IDENTITY(1, 1) CONSTRAINT [PK_RawMaterialInvoiceItem] PRIMARY KEY CLUSTERED,
	item_name       VARCHAR(200) NOT NULL,
	employee_id     INT NOT NULL,
	dt              DATETIME2(0) NOT NULL
)
GO

CREATE UNIQUE NONCLUSTERED INDEX [UQ_RawMaterialInvoiceItem] ON Material.RawMaterialInvoiceItem(item_name)
ON [Indexes]
GO