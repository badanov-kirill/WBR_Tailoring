CREATE TABLE [Sale].[MonthReportDetail]
(
	rrd_id                          INT IDENTITY(1,1) CONSTRAINT [PK_MonthReportDetail] PRIMARY KEY CLUSTERED NOT NULL,
	realizationreport_id            INT NOT NULL,
	period_dt                       DATE NOT NULL,
	suppliercontract_code_id        SMALLINT CONSTRAINT [FK_MonthReportDetail_suppliercontract_code_id] FOREIGN KEY REFERENCES RefBook.SupplierContract(suppliercontract_code_id) 
	NOT NULL,
	gi_id                           INT NOT NULL,
	subject_id                      SMALLINT CONSTRAINT [FK_MonthReportDetail_subject_id] FOREIGN KEY REFERENCES Products.Subjects(subject_id) NOT NULL,
	nm_id                           INT NOT NULL,
	brand_id                        SMALLINT CONSTRAINT [FK_MonthReportDetail_brand_id] FOREIGN KEY REFERENCES Products.Brands(brand_id) NOT NULL,
	sa_id                           INT CONSTRAINT [FK_MonthReportDetail_sa_id] FOREIGN KEY REFERENCES Products.SupplierArticle(sa_id) NOT NULL,
	ts_id                           SMALLINT CONSTRAINT [FK_MonthReportDetail_ts_id] FOREIGN KEY REFERENCES Products.TechSize(ts_id) NOT NULL,
	barcode_id                      INT CONSTRAINT [FK_MonthReportDetail_barcode_id] FOREIGN KEY REFERENCES Products.Barcodes(barcode_id) NOT NULL,
	doc_type_id                     SMALLINT CONSTRAINT [FK_MonthReportDetail_doc_type_id] FOREIGN KEY REFERENCES RefBook.DocTypes(doc_type_id) NOT NULL,
	quantity                        SMALLINT NOT NULL,
	nds                             TINYINT NOT NULL,
	cost_amount                     DECIMAL(9, 2) NOT NULL,
	retail_price                    DECIMAL(9, 2) NOT NULL,
	retail_amount                   DECIMAL(9, 2) NOT NULL,
	retail_commission               DECIMAL(9, 2) NOT NULL,
	sale_percent                    DECIMAL(5, 2) NOT NULL,
	commission_percent              DECIMAL(5, 2) NOT NULL,
	customer_reward                 DECIMAL(9, 2) NOT NULL,
	supplier_reward                 DECIMAL(9, 2) NOT NULL,
	office_id                       SMALLINT CONSTRAINT [FK_MonthReportDetail_office_id] FOREIGN KEY REFERENCES RefBook.Offices(office_id) NOT NULL,
	supplier_oper_id                SMALLINT CONSTRAINT [FK_MonthReportDetail_supplier_oper_id] FOREIGN KEY REFERENCES RefBook.SupplierOper(supplier_oper_id) NOT NULL,
	order_dt                        DATE NOT NULL,
	sale_dt                         DATE NOT NULL,
	shk_id                          BIGINT NOT NULL,
	retail_price_withdisc_rub       DECIMAL(9, 2) NOT NULL,
	for_pay                         DECIMAL(9, 2) NOT NULL,
	for_pay_nds                     DECIMAL(9, 2) NOT NULL,
	delivery_amount                 DECIMAL(9, 2) NOT NULL,
	return_amount                   DECIMAL(9, 2) NOT NULL,
	delivery_rub                    DECIMAL(9, 2) NOT NULL,
	gi_box_type_id                  SMALLINT CONSTRAINT [FK_MonthReportDetail_gi_box_type_id] FOREIGN KEY REFERENCES RefBook.GoodsIncomeBoxType(gi_box_type_id) NOT NULL,
	product_discount_for_report     TINYINT NOT NULL,
	supplier_promo                  TINYINT NOT NULL,
	supplier_spp                    TINYINT NOT NULL,
	CONSTRAINT [FK_MonthReportDetail_realizationreport_id_period_dt] FOREIGN KEY(realizationreport_id, period_dt) REFERENCES Sale.MonthReport(realizationreport_id, period_dt)
)

GO 
CREATE NONCLUSTERED INDEX [IX_MonthReportDetail_doc_type_id_sale_dt_shk_id_quantity]
ON Sale.MonthReportDetail (doc_type_id, sale_dt, shk_id, quantity) ON [Indexes]

GO
CREATE NONCLUSTERED INDEX [IX_MonthReportDetail_realizationreport_id_doc_type_id_quantity]
ON Sale.MonthReportDetail (realizationreport_id,doc_type_id,quantity)
INCLUDE (rrd_id,sa_id,nds,retail_amount,sale_dt,shk_id) ON [Indexes]