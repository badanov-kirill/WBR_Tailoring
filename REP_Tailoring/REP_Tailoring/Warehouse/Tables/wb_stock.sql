CREATE TABLE [Warehouse].[wb_stock]
(
	period_dt                  DATE NOT NULL,
	subject_id                 SMALLINT CONSTRAINT [FK_wb_stock_subject_id] FOREIGN KEY REFERENCES Products.Subjects(subject_id) NOT NULL,
	nm_id                      INT NOT NULL,
	brand_id                   SMALLINT CONSTRAINT [FK_wb_stock_brand_id] FOREIGN KEY REFERENCES Products.Brands(brand_id) NOT NULL,
	sa_id                      INT CONSTRAINT [FK_wb_stock_sa_id] FOREIGN KEY REFERENCES Products.SupplierArticle(sa_id) NOT NULL,
	ts_id                      SMALLINT CONSTRAINT [FK_wb_stock_ts_id] FOREIGN KEY REFERENCES Products.TechSize(ts_id) NOT NULL,
	barcode_id                 INT CONSTRAINT [FK_wb_stock_barcode_id] FOREIGN KEY REFERENCES Products.Barcodes(barcode_id) NOT NULL,
	office_id                  SMALLINT CONSTRAINT [FK_wb_stock_office_id] FOREIGN KEY REFERENCES RefBook.Offices(office_id) NOT NULL,
	quantity                   SMALLINT NOT NULL,
	quantity_full              SMALLINT NOT NULL,
	quantity_not_in_orders     SMALLINT NOT NULL,
	in_way_to_client           SMALLINT NOT NULL,
	in_way_from_client         SMALLINT NOT NULL,
	days_on_site               SMALLINT NOT NULL,
	CONSTRAINT [PK_wb_stock] PRIMARY KEY CLUSTERED (period_dt, nm_id, ts_id, barcode_id, office_id)
)
