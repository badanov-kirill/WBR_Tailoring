CREATE TABLE [Suppliers].[SupplierContract]
(
	suppliercontract_id         INT IDENTITY(1, 1) NOT NULL,
	supplier_id                 INT NULL,
	suppliercontract_code       VARCHAR(9) NOT NULL,
	suppliercontract_name       VARCHAR(100) NOT NULL,
	contract_number             VARCHAR(100) NOT NULL,
	is_default                  BIT NOT NULL,
	suppliercontract_erp_id     INT NULL,
	payment_delay_day           SMALLINT NULL,
	currency_id                 INT NULL,
	buh_uid                     UNIQUEIDENTIFIER NULL,
	CONSTRAINT [PK_SupplierContract_suppliercontract_id] PRIMARY KEY CLUSTERED(suppliercontract_id ASC),
	CONSTRAINT [FK_SupplierContract_currency_id] FOREIGN KEY(currency_id) REFERENCES RefBook.Currency (currency_id),
	CONSTRAINT [FK_SupplierContract_supplier_id] FOREIGN KEY(supplier_id) REFERENCES Suppliers.Supplier (supplier_id)
);


GO

CREATE UNIQUE NONCLUSTERED INDEX [UQ_SupplierContract_supplier_id_id_default] ON Suppliers.SupplierContract(supplier_id, is_default) WHERE is_default = 1 AND supplier_id IS NOT NULL ON 
[Indexes]

GO

CREATE UNIQUE NONCLUSTERED INDEX [UQ_SupplierContract_suppliercontract_erp_id] ON Suppliers.SupplierContract(suppliercontract_erp_id) WHERE 
suppliercontract_erp_id IS NOT NULL  ON [Indexes]

GO

CREATE UNIQUE NONCLUSTERED INDEX [UQ_SupplierContract_buh_uid] ON Suppliers.SupplierContract(buh_uid) WHERE 
buh_uid IS NOT NULL  ON [Indexes]

GO
GRANT SELECT
    ON OBJECT::[Suppliers].[SupplierContract] TO [wildberries\olap-orr]
    AS [dbo];

