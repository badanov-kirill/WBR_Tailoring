CREATE TABLE [Suppliers].[AlterSupplier]
(
	alter_supplier_id       INT IDENTITY(1, 1) CONSTRAINT [PK_AlterSupplier] PRIMARY KEY CLUSTERED NOT NULL,
	alter_supplier_name     VARCHAR(100) NOT NULL,
	is_deleted              BIT NOT NULL,
	label_info              VARCHAR(500) NULL,
	dt                      DATETIME2(0) NOT NULL,
	employee_id             INT NOT NULL
)

GO 
CREATE UNIQUE NONCLUSTERED INDEX [UQ_AlterSupplier_alter_supplier_name] ON Suppliers.AlterSupplier(alter_supplier_name) WHERE is_deleted = 0 ON [Indexes]