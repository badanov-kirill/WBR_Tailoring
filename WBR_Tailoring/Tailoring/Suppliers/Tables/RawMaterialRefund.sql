CREATE TABLE [Suppliers].[RawMaterialRefund]
(
	rmr_id                  INT NOT NULL IDENTITY(1,1) CONSTRAINT [PK_RawMaterialRefund] PRIMARY KEY CLUSTERED, 
	supplier_id             INT NOT NULL CONSTRAINT [FK_RawMaterialRefund_supplier_id] FOREIGN KEY REFERENCES Suppliers.Supplier(supplier_id),
	suppliercontract_id     INT NOT NULL CONSTRAINT [FK_RawMaterialRefund_suppliercontract_id] FOREIGN KEY REFERENCES Suppliers.SupplierContract(suppliercontract_id),
	rmrs_id                 TINYINT NOT NULL CONSTRAINT [FK_RawMaterialRefund_rmrs_id] FOREIGN KEY REFERENCES Suppliers.RawMaterialRefundStatus(rmrs_id),
	sending_dt              DATE NULL,
	is_deleted              BIT NOT NULL,
	rv                      ROWVERSION NOT NULL,
	create_dt               DATETIME2(0) NOT NULL,
	create_employee_id      INT NOT NULL,
	dt                      DATETIME2(0) NOT NULL,
	employee_id             INT NOT NULL,	
	comment                 VARCHAR(200) NULL
)
GO