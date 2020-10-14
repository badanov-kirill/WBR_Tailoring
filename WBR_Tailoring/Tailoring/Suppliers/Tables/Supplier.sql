CREATE TABLE [Suppliers].[Supplier]
(
	supplier_id            INT CONSTRAINT [PK_Supplier_supplier_id] PRIMARY KEY CLUSTERED NOT NULL,
	supplier_name          VARCHAR(100) NOT NULL,
	employee_id            INT NOT NULL,
	dt                     DATETIME CONSTRAINT DF_Supplier_dt DEFAULT(GETDATE()) NOT NULL,
	is_deleted             BIT NOT NULL,
	buh_cod                VARCHAR(9) NULL,
	buh_uid                UNIQUEIDENTIFIER NULL,
	supplier_source_id     TINYINT NOT NULL
)
GO

CREATE UNIQUE NONCLUSTERED INDEX [UQ_Supplier_supplier_name_source] ON Suppliers.Supplier(supplier_name, supplier_source_id) ON [Indexes]

GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_Supplier_buh_uid] ON Suppliers.Supplier(buh_uid) WHERE buh_uid IS NOT NULL  ON [Indexes]

GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_Supplier_buh_cod] ON Suppliers.Supplier(buh_cod) WHERE buh_cod IS NOT NULL ON [Indexes]