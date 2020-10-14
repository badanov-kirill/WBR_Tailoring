CREATE TABLE [SyncFinance].[MaterialStuffSupply]
(
	doc_id                    INT CONSTRAINT [PK_SyncFinance_MaterialStuffSupply] PRIMARY KEY CLUSTERED NOT NULL,
	doc_dt                    DATETIME2(0) NOT NULL,
	supplier_id               INT NOT NULL,
	suppliercontract_code     VARCHAR(9) NOT NULL,
	ttn_name                  VARCHAR(30) NULL,
	ttn_dt                    DATE NULL,
	invoice_name              VARCHAR(30) NOT NULL,
	invoice_dt                DATE NOT NULL,
	employee_id               INT NOT NULL,
	is_deleted                BIT NOT NULL,
	mol_sr_id                 INT NULL,
	comment                   VARCHAR(300) NULL,
	currency_id               INT CONSTRAINT [FK_SyncFinance_MaterialStuffSupply] FOREIGN KEY REFERENCES RefBook.Currency(currency_id) NOT NULL,
	hash_string               CHAR(32) NOT NULL,
	hash_dt                   DATETIME2(0) NOT NULL,
	rv                        ROWVERSION NOT NULL,
	ots_id					  INT NULL
)
