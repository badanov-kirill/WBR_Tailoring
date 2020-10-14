CREATE TABLE [Suppliers].[RawMaterialOrder]
(
	rmo_id                  INT IDENTITY(1, 1) CONSTRAINT [PK_RawMaterialOrder] PRIMARY KEY CLUSTERED NOT NULL,
	create_dt               DATETIME2(0) NOT NULL,
	create_employee_id      INT NOT NULL,
	supplier_id             INT CONSTRAINT [FK_RawMaterialOrder_supplier_id] FOREIGN KEY REFERENCES Suppliers.Supplier(supplier_id) NOT NULL,
	suppliercontract_id     INT CONSTRAINT [FK_RawMaterialOrder_suppliercontract_id] FOREIGN KEY REFERENCES Suppliers.SupplierContract(suppliercontract_id) NOT NULL,
	supply_dt               DATETIME2(0) NOT NULL,
	is_deleted              BIT NOT NULL,
	comment                 VARCHAR(200) NULL,
	employee_id             INT NOT NULL,
	dt                      DATETIME2(0) NOT NULL,
	approve_dt              DATETIME2(0) NULL,
	approve_employee_id     INT NULL
)
