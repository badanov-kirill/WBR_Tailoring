CREATE PROCEDURE [Sale].[MonthRedortDetail_GetByID]
	@realizationreport_id INT,
	@period_dt DATE
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	s.subject_name,
			sa.sa_name,
			ts.ts_name,
			b.brand_name,
			mrd.quantity,
			mrd.nds,
			mrd.cost_amount,
			mrd.retail_price,
			mrd.retail_amount,
			mrd.retail_commission,
			mrd.retail_price_withdisc_rub,
			mrd.for_pay,
			mrd.for_pay_nds,
			mrd.shk_id,
			CAST(mrd.sale_dt AS DATETIME) sale_dt,
			oa_ret.rrd_id            return_rrd_id,
			oa_ret.retail_amount     return_retail_amount
	INTO	#t
	FROM	Sale.MonthReportDetail mrd   
			INNER JOIN	Products.Brands b
				ON	b.brand_id = mrd.brand_id   
			INNER JOIN	Products.Subjects s
				ON	s.subject_id = mrd.subject_id   
			INNER JOIN	Products.SupplierArticle sa
				ON	sa.sa_id = mrd.sa_id   
			INNER JOIN	Products.TechSize ts
				ON	ts.ts_id = mrd.ts_id   
			OUTER APPLY (
			      	SELECT	mrd2.rrd_id,
			      			mrd2.cost_amount,
			      			mrd2.retail_amount
			      	FROM	Sale.MonthReportDetail mrd2
			      	WHERE	mrd2.shk_id = mrd.shk_id
			      			AND	mrd2.doc_type_id = 2
			      			AND	mrd2.sale_dt = mrd.sale_dt
			      			AND	mrd2.quantity = 1
			      			AND mrd2.realizationreport_id = @realizationreport_id
			      			AND mrd2.period_dt = @period_dt
			      ) oa_ret
	WHERE	mrd.doc_type_id = 1
			AND	mrd.quantity != 0
			AND	mrd.realizationreport_id = @realizationreport_id
			AND	mrd.period_dt = @period_dt
	ORDER BY
		mrd.rrd_id DESC
	
	SELECT	t.subject_name,
			t.sa_name,
			t.ts_name,
			t.brand_name,
			t.quantity,
			t.nds,
			t.cost_amount,
			t.retail_price,
			t.retail_amount,
			t.retail_commission,
			t.retail_price_withdisc_rub,
			t.for_pay,
			t.for_pay_nds,
			t.shk_id,
			t.sale_dt,
			t.return_rrd_id,
			t.return_retail_amount
	FROM	#t t
	
	SELECT	s.subject_name,
			sa.sa_name,
			ts.ts_name,
			b.brand_name,
			mrd.quantity,
			mrd.nds,
			mrd.cost_amount,
			mrd.retail_price,
			mrd.retail_amount,
			mrd.retail_commission,
			mrd.retail_price_withdisc_rub,
			mrd.for_pay,
			mrd.for_pay_nds,
			mrd.shk_id,
			mrd.sale_dt,
			CASE 
			     WHEN t.return_rrd_id IS NULL THEN 0
			     ELSE 1
			END        is_return_this_period
	FROM	Sale.MonthReportDetail mrd   
			INNER JOIN	Products.Brands b
				ON	b.brand_id = mrd.brand_id   
			INNER JOIN	Products.Subjects s
				ON	s.subject_id = mrd.subject_id   
			INNER JOIN	Products.SupplierArticle sa
				ON	sa.sa_id = mrd.sa_id   
			INNER JOIN	Products.TechSize ts
				ON	ts.ts_id = mrd.ts_id   
			LEFT JOIN	#t t
				ON	t.return_rrd_id = mrd.rrd_id
	WHERE	mrd.doc_type_id = 2
			AND	mrd.quantity != 0
			AND	mrd.realizationreport_id = @realizationreport_id
			AND	mrd.period_dt = @period_dt
	ORDER BY
		mrd.rrd_id     DESC
	
	SELECT	SUM(CASE WHEN mrd.doc_type_id = 1 THEN mrd.retail_amount ELSE 0 END) retail_amount,
			SUM(CASE WHEN mrd.doc_type_id = 1 THEN mrd.retail_commission ELSE 0 END) retail_commission,
			SUM(mrd.delivery_rub)      delivery_sum,
			SUM(CASE WHEN mrd.doc_type_id = 1 THEN mrd.retail_commission ELSE 0 END) - SUM(CASE WHEN mrd.doc_type_id = 2 THEN mrd.retail_commission ELSE 0 END) 
			retail_commission_with_return,
			SUM(CASE WHEN mrd.doc_type_id = 2 THEN mrd.retail_amount ELSE 0 END) return_amount,
			SUM(CASE WHEN mrd.doc_type_id = 2 THEN mrd.retail_commission ELSE 0 END) return_commission,
			SUM(CASE WHEN mrd.doc_type_id = 1 THEN mrd.retail_amount ELSE 0 END) - SUM(mrd.delivery_rub) -(SUM(CASE WHEN mrd.doc_type_id = 1 THEN mrd.retail_commission ELSE 0 END) - SUM(CASE WHEN mrd.doc_type_id = 2 THEN mrd.retail_commission ELSE 0 END)) 
			- SUM(CASE WHEN mrd.doc_type_id = 2 THEN mrd.retail_amount ELSE 0 END) full_amount
	FROM	Sale.MonthReportDetail     mrd
	WHERE	mrd.realizationreport_id = @realizationreport_id
			AND	mrd.period_dt = @period_dt
	
	SELECT	DISTINCT sa.sa_name
	FROM	Sale.MonthReportDetail mrd   
			INNER JOIN	Products.Brands b
				ON	b.brand_id = mrd.brand_id   
			INNER JOIN	Products.Subjects s
				ON	s.subject_id = mrd.subject_id   
			INNER JOIN	Products.SupplierArticle sa
				ON	sa.sa_id = mrd.sa_id   
			INNER JOIN	Products.TechSize ts
				ON	ts.ts_id = mrd.ts_id
	WHERE	mrd.quantity != 0
			AND	mrd.realizationreport_id = @realizationreport_id
			AND	mrd.period_dt = @period_dt
	
	DROP TABLE #t