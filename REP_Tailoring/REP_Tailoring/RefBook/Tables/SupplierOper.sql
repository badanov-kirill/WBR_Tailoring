CREATE TABLE [RefBook].[SupplierOper]
(
	supplier_oper_id                SMALLINT IDENTITY(1,1) CONSTRAINT [PK_SupplierOper] PRIMARY KEY CLUSTERED NOT NULL,
	supplier_oper_name VARCHAR(50) NOT NULL
)

GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_SupplierOper_supplier_oper_name] ON RefBook.SupplierOper(supplier_oper_name) INCLUDE(supplier_oper_id) ON [Indexes]