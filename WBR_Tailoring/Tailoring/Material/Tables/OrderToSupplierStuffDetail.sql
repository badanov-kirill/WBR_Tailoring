CREATE TABLE [Material].[OrderToSupplierStuffDetail]
(
	otssd_id              INT CONSTRAINT [PK_OrderToSupplierStuffDetail] PRIMARY KEY CLUSTERED NOT NULL,
	ots_id                INT NOT NULL,
	nomenclature_code     VARCHAR(250) NULL,
	nomenclature_name     VARCHAR(500) NULL,
	stuff_model_id        INT CONSTRAINT [FK_OrderToSupplierStuffDetail_stuff_model_id] FOREIGN KEY REFERENCES Material.SpecificationStuffModel(stuff_model_id) NULL,
	qty                   DECIMAL(15, 3) NOT NULL,
	price                 DECIMAL(15, 2) NULL,
	nds                   TINYINT,
	amount                DECIMAL(15, 2) NULL,
	okei_id               INT NULL,
	receipt_dt            DATE NULL,
	days_before_pay       INT NULL,
	plan_pay_dt           DATE NULL,
	price_with_vat        DECIMAL(15, 2) NULL,
)
GO

CREATE NONCLUSTERED INDEX [IX_OrderToSupplierStuffDetail_ots_id]
ON Material.OrderToSupplierStuffDetail(ots_id) 
ON [Indexes];