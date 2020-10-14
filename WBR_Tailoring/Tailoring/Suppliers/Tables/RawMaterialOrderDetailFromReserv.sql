CREATE TABLE [Suppliers].[RawMaterialOrderDetailFromReserv]
(
	rmodr_id        INT IDENTITY(1, 1) CONSTRAINT [PK_RawMaterialOrderDetailFromReserv] PRIMARY KEY CLUSTERED NOT NULL,
	rmo_id          INT CONSTRAINT [FK_RawMaterialOrderDetailFromReserv_rmo_id] FOREIGN KEY REFERENCES Suppliers.RawMaterialOrder(rmo_id) NOT NULL,
	rmsr_id         INT CONSTRAINT [FK_RawMaterialOrderDetailFromReserv_rmsr_id] FOREIGN KEY REFERENCES Suppliers.RawMaterialStockReserv(rmsr_id) NOT NULL,
	qty             DECIMAL(9, 3) NOT NULL,
	price_cur       DECIMAL(9, 2) NOT NULL,
	currency_id     INT CONSTRAINT [FK_RawMaterialOrderDetailFromReserv_currency_id] FOREIGN KEY REFERENCES RefBook.Currency(currency_id) NOT NULL,
	rmods_id        TINYINT CONSTRAINT [FK_RawMaterialOrderDetailFromReserv] FOREIGN KEY REFERENCES Suppliers.RawMaterialOrderDetailStatus(rmods_id) NOT NULL,
	employee_id     INT NULL,
	dt              DATETIME2(0) NULL
)

GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_RawMaterialOrderDetailFromReserv_rmsr_id] ON Suppliers.RawMaterialOrderDetailFromReserv(rmsr_id) ON [Indexes]