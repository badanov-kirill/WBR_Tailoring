CREATE TYPE [Sale].[MonthReportDetailType] AS TABLE (
	   	                                                                                   	rrd_id BIGINT NOT NULL,
	   	                                                                                   	realizationreport_id INT NOT NULL,
	   	                                                                                   	suppliercontract_code VARCHAR(15) NULL,
	   	                                                                                   	gi_id INT NOT NULL,
	   	                                                                                   	subject_name VARCHAR(50) NULL,
	   	                                                                                   	nm_id INT NOT NULL,
	   	                                                                                   	brand_name VARCHAR(50) NULL,
	   	                                                                                   	sa_name VARCHAR(36) NULL,
	   	                                                                                   	ts_name VARCHAR(15) NULL,
	   	                                                                                   	barcode VARCHAR(30) NULL,
	   	                                                                                   	doc_type_name VARCHAR(50) NULL,
	   	                                                                                   	quantity SMALLINT NOT NULL,
	   	                                                                                   	nds TINYINT NOT NULL,
	   	                                                                                   	cost_amount DECIMAL(9, 2) NOT NULL,
	   	                                                                                   	retail_price DECIMAL(9, 2) NOT NULL,
	   	                                                                                   	retail_amount DECIMAL(9, 2) NOT NULL,
	   	                                                                                   	retail_commission DECIMAL(9, 2) NOT NULL,
	   	                                                                                   	sale_percent DECIMAL(5, 2) NOT NULL,
	   	                                                                                   	commission_percent DECIMAL(5, 2) NOT NULL,
	   	                                                                                   	customer_reward DECIMAL(9, 2) NOT NULL,
	   	                                                                                   	supplier_reward DECIMAL(9, 2) NOT NULL,
	   	                                                                                   	office_name VARCHAR(50) NULL,
	   	                                                                                   	supplier_oper_name VARCHAR(50) NULL,
	   	                                                                                   	order_dt DATE NOT NULL,
	   	                                                                                   	sale_dt DATE NOT NULL,
	   	                                                                                   	shk_id BIGINT NOT NULL,
	   	                                                                                   	retail_price_withdisc_rub DECIMAL(9, 2) NOT NULL,
	   	                                                                                   	for_pay DECIMAL(9, 2) NOT NULL,
	   	                                                                                   	for_pay_nds DECIMAL(9, 2) NOT NULL,
	   	                                                                                   	delivery_amount DECIMAL(9, 2) NOT NULL,
	   	                                                                                   	return_amount DECIMAL(9, 2) NOT NULL,
	   	                                                                                   	delivery_rub DECIMAL(9, 2) NOT NULL,
	   	                                                                                   	gi_box_type_name VARCHAR(50) NULL,
	   	                                                                                   	product_discount_for_report TINYINT NOT NULL,
	   	                                                                                   	supplier_promo TINYINT NOT NULL,
	   	                                                                                   	supplier_spp TINYINT NOT NULL
	   	                                                                                   )
GO

GRANT EXECUTE
    ON TYPE::[Sale].[MonthReportDetailType] TO PUBLIC;
GO