CREATE TABLE [Planing].[SketchPlanSupplierPrice]
(
	spsp_id         INT IDENTITY(1, 1) CONSTRAINT [PK_SketchPlanSupplierPrice] PRIMARY KEY CLUSTERED NOT NULL,
	sp_id           INT CONSTRAINT [FK_SketchPlanSupplierPrice_sp_id] FOREIGN KEY REFERENCES Planing.SketchPlan(sp_id) NOT NULL,
	supplier_id     INT CONSTRAINT [FK_SketchPlanSupplierPrice_supplier_id] FOREIGN KEY REFERENCES Suppliers.Supplier(supplier_id) NOT NULL,
	price_ru        DECIMAL(9, 2) NOT NULL,
	dt              DATETIME2(0) NOT NULL,
	employee_id     INT NOT NULL,
	comment         VARCHAR(200) NULL,
	order_num		VARCHAR(10) NULL
)

GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_SketchPlanSupplierPrice_sp_id_supplier_id] ON Planing.SketchPlanSupplierPrice(sp_id, supplier_id) ON [Indexes]