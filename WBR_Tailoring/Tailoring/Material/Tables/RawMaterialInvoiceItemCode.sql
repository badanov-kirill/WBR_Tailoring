CREATE TABLE [Material].[RawMaterialInvoiceItemCode]
(
	rmiic_id      INT NOT NULL IDENTITY(1, 1) CONSTRAINT [PK_RawMaterialInvoiceItemCode] PRIMARY KEY CLUSTERED,
	item_code     VARCHAR(200) NOT NULL
)
GO

CREATE UNIQUE NONCLUSTERED INDEX [UQ_RawMaterialInvoiceItemCode] ON Material.RawMaterialInvoiceItemCode(item_code)
ON [Indexes]
GO