CREATE PROCEDURE [Sale].[MonthReport_Load]
	@period_dt DATE,
	@period_to_dt DATE,
	@detail Sale.MonthReportDetailType READONLY,
	@first_packet BIT
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	
	DECLARE @dt DATETIME2(0) = GETDATE()
	DECLARE @report_id_tab TABLE (realizationreport_id INT PRIMARY KEY CLUSTERED NOT NULL)
	DECLARE @data_tab TABLE (
				rrd_id BIGINT NOT NULL,
	        	realizationreport_id INT NOT NULL,
	        	suppliercontract_code VARCHAR(15) NOT NULL,
	        	gi_id INT NOT NULL,
	        	subject_name VARCHAR(50) NOT NULL,
	        	nm_id INT NOT NULL,
	        	brand_name VARCHAR(50) NOT NULL,
	        	sa_name VARCHAR(36) NOT NULL,
	        	ts_name VARCHAR(15) NOT NULL,
	        	barcode VARCHAR(30) NOT NULL,
	        	doc_type_name VARCHAR(50) NOT NULL,
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
	        	office_name VARCHAR(50) NOT NULL,
	        	supplier_oper_name VARCHAR(50) NOT NULL,
	        	order_dt DATE NOT NULL,
	        	sale_dt DATE NOT NULL,
	        	shk_id BIGINT NOT NULL,
	        	retail_price_withdisc_rub DECIMAL(9, 2) NOT NULL,
	        	for_pay DECIMAL(9, 2) NOT NULL,
	        	for_pay_nds DECIMAL(9, 2) NOT NULL,
	        	delivery_amount DECIMAL(9, 2) NOT NULL,
	        	return_amount DECIMAL(9, 2) NOT NULL,
	        	delivery_rub DECIMAL(9, 2) NOT NULL,
	        	gi_box_type_name VARCHAR(50) NOT NULL,
	        	product_discount_for_report TINYINT NOT NULL,
	        	supplier_promo TINYINT NOT NULL,
	        	supplier_spp TINYINT NOT NULL,
	        	suppliercontract_code_id SMALLINT NULL,
	        	subject_id SMALLINT NULL,
	        	brand_id SMALLINT NULL,
	        	sa_id INT NULL,
	        	ts_id SMALLINT NULL,
	        	barcode_id INT NULL,
	        	doc_type_id SMALLINT NULL,
	        	office_id SMALLINT NULL,
	        	supplier_oper_id SMALLINT NULL,
	        	gi_box_type_id SMALLINT NULL
	        )
	
	INSERT INTO @data_tab
		(
			rrd_id,
			realizationreport_id,
			suppliercontract_code,
			gi_id,
			subject_name,
			nm_id,
			brand_name,
			sa_name,
			ts_name,
			barcode,
			doc_type_name,
			quantity,
			nds,
			cost_amount,
			retail_price,
			retail_amount,
			retail_commission,
			sale_percent,
			commission_percent,
			customer_reward,
			supplier_reward,
			office_name,
			supplier_oper_name,
			order_dt,
			sale_dt,
			shk_id,
			retail_price_withdisc_rub,
			for_pay,
			for_pay_nds,
			delivery_amount,
			return_amount,
			delivery_rub,
			gi_box_type_name,
			product_discount_for_report,
			supplier_promo,
			supplier_spp
		)
	SELECT	d.rrd_id,
			d.realizationreport_id,
			ISNULL(d.suppliercontract_code, '') suppliercontract_code,
			d.gi_id,
			ISNULL(d.subject_name, '')      subject_name,
			d.nm_id,
			ISNULL(d.brand_name, '')        brand_name,
			ISNULL(d.sa_name, '')           sa_name,
			ISNULL(d.ts_name, '')           ts_name,
			ISNULL(d.barcode, '')           barcode,
			ISNULL(d.doc_type_name, '')     doc_type_name,
			d.quantity,
			d.nds,
			d.cost_amount,
			d.retail_price,
			d.retail_amount,
			d.retail_commission,
			d.sale_percent,
			d.commission_percent,
			d.customer_reward,
			d.supplier_reward,
			ISNULL(d.office_name, '')       office_name,
			ISNULL(d.supplier_oper_name, '') supplier_oper_name,
			d.order_dt,
			d.sale_dt,
			d.shk_id,
			d.retail_price_withdisc_rub,
			d.for_pay,
			d.for_pay_nds,
			d.delivery_amount,
			d.return_amount,
			d.delivery_rub,
			ISNULL(d.gi_box_type_name, '') gi_box_type_name,
			d.product_discount_for_report,
			d.supplier_promo,
			d.supplier_spp
	FROM	@detail                         d
	
	BEGIN TRY
		INSERT INTO RefBook.SupplierContract
			(
				suppliercontract_code
			)
		SELECT	DISTINCT dt.suppliercontract_code
		FROM	@data_tab dt
		WHERE	NOT EXISTS (
		     		SELECT	1
		     		FROM	RefBook.SupplierContract sc
		     		WHERE	sc.suppliercontract_code = dt.suppliercontract_code
		     	)
		
		INSERT INTO Products.Subjects
			(
				subject_name
			)
		SELECT	DISTINCT dt.subject_name
		FROM	@data_tab dt
		WHERE	NOT EXISTS (
		     		SELECT	1
		     		FROM	Products.Subjects dc
		     		WHERE	dc.subject_name = dt.subject_name
		     	)
		
		INSERT INTO Products.Brands
			(
				brand_name
			)
		SELECT	DISTINCT dt.brand_name
		FROM	@data_tab dt
		WHERE	NOT EXISTS (
		     		SELECT	1
		     		FROM	Products.Brands dc
		     		WHERE	dc.brand_name = dt.brand_name
		     	)
		
		INSERT INTO Products.SupplierArticle
			(
				sa_name
			)
		SELECT	DISTINCT dt.sa_name
		FROM	@data_tab dt
		WHERE	NOT EXISTS (
		     		SELECT	1
		     		FROM	Products.SupplierArticle dc
		     		WHERE	dc.sa_name = dt.sa_name
		     	)
		
		INSERT INTO Products.TechSize
			(
				ts_name
			)
		SELECT	DISTINCT dt.ts_name
		FROM	@data_tab dt
		WHERE	NOT EXISTS (
		     		SELECT	1
		     		FROM	Products.TechSize dc
		     		WHERE	dc.ts_name = dt.ts_name
		     	)
		
		INSERT INTO Products.Barcodes
			(
				barcode
			)
		SELECT	DISTINCT dt.barcode
		FROM	@data_tab dt
		WHERE	NOT EXISTS (
		     		SELECT	1
		     		FROM	Products.Barcodes dc
		     		WHERE	dc.barcode = dt.barcode
		     	)
		
		INSERT INTO RefBook.DocTypes
			(
				doc_type_name
			)
		SELECT	DISTINCT dt.doc_type_name
		FROM	@data_tab dt
		WHERE	NOT EXISTS (
		     		SELECT	1
		     		FROM	RefBook.DocTypes dc
		     		WHERE	dc.doc_type_name = dt.doc_type_name
		     	)
		
		INSERT INTO RefBook.Offices
			(
				office_name
			)
		SELECT	DISTINCT dt.office_name
		FROM	@data_tab dt
		WHERE	NOT EXISTS (
		     		SELECT	1
		     		FROM	RefBook.Offices dc
		     		WHERE	dc.office_name = dt.office_name
		     	)
		
		INSERT INTO RefBook.SupplierOper
			(
				supplier_oper_name
			)
		SELECT	DISTINCT dt.supplier_oper_name
		FROM	@data_tab dt
		WHERE	NOT EXISTS (
		     		SELECT	1
		     		FROM	RefBook.SupplierOper dc
		     		WHERE	dc.supplier_oper_name = dt.supplier_oper_name
		     	)
		
		INSERT INTO RefBook.GoodsIncomeBoxType
			(
				gi_box_type_name
			)
		SELECT	DISTINCT dt.gi_box_type_name
		FROM	@data_tab dt
		WHERE	NOT EXISTS (
		     		SELECT	1
		     		FROM	RefBook.GoodsIncomeBoxType dc
		     		WHERE	dc.gi_box_type_name = dt.gi_box_type_name
		     	)
		
		UPDATE	dt
		SET 	suppliercontract_code_id = sc.suppliercontract_code_id,
				subject_id = sj.subject_id,
				brand_id = br.brand_id,
				sa_id = sa.sa_id,
				ts_id = ts.ts_id,
				barcode_id = bc.barcode_id,
				doc_type_id = dtp.doc_type_id,
				office_id = o.office_id,
				supplier_oper_id = so.supplier_oper_id,
				gi_box_type_id = bt.gi_box_type_id
		FROM	@data_tab dt
				INNER JOIN	Products.Barcodes bc
					ON	bc.barcode = dt.barcode
				INNER JOIN	Products.Brands br
					ON	br.brand_name = dt.brand_name
				INNER JOIN	Products.Subjects sj
					ON	sj.subject_name = dt.subject_name
				INNER JOIN	Products.SupplierArticle sa
					ON	sa.sa_name = dt.sa_name
				INNER JOIN	Products.TechSize ts
					ON	ts.ts_name = dt.ts_name
				INNER JOIN	RefBook.DocTypes dtp
					ON	dtp.doc_type_name = dt.doc_type_name
				INNER JOIN	RefBook.GoodsIncomeBoxType bt
					ON	bt.gi_box_type_name = dt.gi_box_type_name
				INNER JOIN	RefBook.Offices o
					ON	o.office_name = dt.office_name
				INNER JOIN	RefBook.SupplierContract sc
					ON	sc.suppliercontract_code = dt.suppliercontract_code
				INNER JOIN	RefBook.SupplierOper so
					ON	so.supplier_oper_name = dt.supplier_oper_name
		
		INSERT INTO @report_id_tab
			(
				realizationreport_id
			)
		SELECT	DISTINCT dt.realizationreport_id
		FROM	@data_tab dt
		
		IF @first_packet = 0
		   AND EXISTS(
		       	SELECT	1
		       	FROM	@report_id_tab rt   
		       			LEFT JOIN	Sale.MonthReport mr
		       				ON	mr.realizationreport_id = rt.realizationreport_id
		       	WHERE	mr.realizationreport_id IS NULL
		       )
		BEGIN
		    RAISERROR('Ошибочные данные, в одном периоде несколько номеров отчетов', 16, 1)
		    RETURN
		END 
		
			MERGE Sale.MonthReport t
		   USING (
		         	SELECT	rt.realizationreport_id realizationreport_id,
		         			@period_dt period_dt,
		         			@period_to_dt period_to_dt
		         	FROM	@report_id_tab rt
		         ) s
		   		ON t.realizationreport_id = s.realizationreport_id
		   WHEN MATCHED THEN 
		        UPDATE	
		        SET 	t.dt = @dt,
						t.period_to_dt = s.period_to_dt,
						t.period_dt = s.period_dt,
		        		t.cnt_load = CASE 
		        		                  WHEN @first_packet = 1 THEN t.cnt_load + 1
		        		                  ELSE t.cnt_load
		        		             END,
		        		t.cnt_pacages = CASE 
		        		                     WHEN @first_packet = 1 THEN 1
		        		                     ELSE t.cnt_pacages + 1
		        		                END,
		        		t.dt_first_packages = CASE 
		        		                           WHEN @first_packet = 1 THEN @dt
		        		                           ELSE t.dt_first_packages
		        		                      END,
		        		t.dt_last_packages = @dt
		   WHEN NOT MATCHED THEN 
		        INSERT
		        	(
		        		realizationreport_id,
		        		period_dt,
		        		dt,
		        		create_dt,
		        		cnt_load,
		        		cnt_pacages,
		        		dt_first_packages,
		        		dt_last_packages,
		        		period_to_dt
		        	)
		        VALUES
		        	(
		        		s.realizationreport_id,
		        		s.period_dt,
		        		@dt,
		        		@dt,
		        		1,
		        		1,
		        		@dt,
		        		@dt,
		        		s.period_to_dt
		        	);
		
		IF @first_packet = 1
		BEGIN
		    DELETE	mrd
		    FROM	Sale.MonthReportDetail mrd   
		    		INNER JOIN	@report_id_tab t
		    			ON	t.realizationreport_id = mrd.realizationreport_id
		END
		
		INSERT INTO Sale.MonthReportDetail
			(
				realizationreport_id,
				period_dt,
				suppliercontract_code_id,
				gi_id,
				subject_id,
				nm_id,
				brand_id,
				sa_id,
				ts_id,
				barcode_id,
				doc_type_id,
				quantity,
				nds,
				cost_amount,
				retail_price,
				retail_amount,
				retail_commission,
				sale_percent,
				commission_percent,
				customer_reward,
				supplier_reward,
				office_id,
				supplier_oper_id,
				order_dt,
				sale_dt,
				shk_id,
				retail_price_withdisc_rub,
				for_pay,
				for_pay_nds,
				delivery_amount,
				return_amount,
				delivery_rub,
				gi_box_type_id,
				product_discount_for_report,
				supplier_promo,
				supplier_spp
			)
		SELECT	dt.realizationreport_id,
				@period_dt,
				dt.suppliercontract_code_id,
				dt.gi_id,
				dt.subject_id,
				dt.nm_id,
				dt.brand_id,
				dt.sa_id,
				dt.ts_id,
				dt.barcode_id,
				dt.doc_type_id,
				dt.quantity,
				dt.nds,
				dt.cost_amount,
				dt.retail_price,
				dt.retail_amount,
				dt.retail_commission,
				dt.sale_percent,
				dt.commission_percent,
				dt.customer_reward,
				dt.supplier_reward,
				dt.office_id,
				dt.supplier_oper_id,
				dt.order_dt,
				dt.sale_dt,
				dt.shk_id,
				dt.retail_price_withdisc_rub,
				dt.for_pay,
				dt.for_pay_nds,
				dt.delivery_amount,
				dt.return_amount,
				dt.delivery_rub,
				dt.gi_box_type_id,
				dt.product_discount_for_report,
				dt.supplier_promo,
				dt.supplier_spp
		FROM	@data_tab dt
		ORDER BY dt.rrd_id
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
		    ROLLBACK TRANSACTION
		
		DECLARE @ErrNum INT = ERROR_NUMBER();
		DECLARE @estate INT = ERROR_STATE();
		DECLARE @esev INT = ERROR_SEVERITY();
		DECLARE @Line INT = ERROR_LINE();
		DECLARE @Mess VARCHAR(MAX) = CHAR(10) + ISNULL('Процедура: ' + ERROR_PROCEDURE(), '') 
		        + CHAR(10) + ERROR_MESSAGE();
		
		RAISERROR('Ошибка %d в строке %d  %s', @esev, @estate, @ErrNum, @Line, @Mess) 
		WITH LOG;
	END CATCH 