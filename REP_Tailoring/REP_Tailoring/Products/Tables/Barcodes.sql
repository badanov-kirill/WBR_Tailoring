CREATE TABLE [Products].[Barcodes]
(
	barcode_id INT IDENTITY(1,1) CONSTRAINT [PK_Barcodes] PRIMARY KEY CLUSTERED NOT NULL,
	barcode VARCHAR(30) NOT NULL
)

GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_Barcodes_barcode] ON Products.Barcodes(barcode) INCLUDE(barcode_id) ON [Indexes]