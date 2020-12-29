CREATE TABLE [RefBook].[SupplierContract]
(
	suppliercontract_code_id        SMALLINT IDENTITY(1,1) CONSTRAINT [PK_SupplierContract] PRIMARY KEY CLUSTERED NOT NULL,
	suppliercontract_code VARCHAR(15) NOT NULL
)

GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_SupplierContract_suppliercontract_code] ON RefBook.SupplierContract(suppliercontract_code) INCLUDE(suppliercontract_code_id) ON [Indexes]