﻿CREATE PROCEDURE [Sale].[MonthRedortDetail_GetByID_v2]
	@realizationreport_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	sa.sa_name,
			ts.ts_name,
			1                          quantity,
			MAX(mrd.nds)               nds,
			SUM(mrd.retail_amount)     retail_amount,
			MAX(CAST(CASE WHEN mrd.sale_dt >= mr.period_dt AND mrd.sale_dt <= mr.period_to_dt THEN mrd.sale_dt ELSE mr.period_dt END AS DATETIME))
			sale_dt,
			MAX(
				CAST(DATEADD(DAY, 1, EOMONTH((CASE WHEN mrd.sale_dt >= mr.period_dt AND mrd.sale_dt <= mr.period_to_dt THEN mrd.sale_dt ELSE mr.period_dt END), -1)) AS DATETIME)
			)                          sale_period_dt,
			MIN(mrd.rrd_id)            rrd_id
	FROM	Sale.MonthReportDetail mrd   
			INNER JOIN	Sale.MonthReport mr
				ON	mr.realizationreport_id = mrd.realizationreport_id   
			INNER JOIN	Products.SupplierArticle sa
				ON	sa.sa_id = mrd.sa_id   
			INNER JOIN	Products.TechSize ts
				ON	ts.ts_id = mrd.ts_id
	WHERE	mrd.doc_type_id = 1
			AND	mrd.quantity != 0
			AND	mrd.realizationreport_id = @realizationreport_id
			AND	mrd.retail_amount != 0
	GROUP BY
		mrd.shk_id,
		sa.sa_name,
		ts.ts_name
	ORDER BY
		rrd_id                         DESC
		
		--SELECT	sa.sa_name,
		--		ts.ts_name,
		--		mrd.quantity,
		--		mrd.nds,
		--		mrd.retail_amount,
		--		CAST(CASE WHEN mrd.sale_dt >= mr.period_dt AND mrd.sale_dt <= mr.period_to_dt THEN mrd.sale_dt ELSE mr.period_dt END AS DATETIME)
		--		sale_dt,
		--		CAST(
		--			DATEADD(DAY, 1, EOMONTH((CASE WHEN mrd.sale_dt >= mr.period_dt AND mrd.sale_dt <= mr.period_to_dt THEN mrd.sale_dt ELSE mr.period_dt END), -1))
		--			AS DATETIME
		--		) sale_period_dt
		--FROM	Sale.MonthReportDetail mrd
		--		INNER JOIN	Sale.MonthReport mr
		--			ON	mr.realizationreport_id = mrd.realizationreport_id
		--		INNER JOIN	Products.SupplierArticle sa
		--			ON	sa.sa_id = mrd.sa_id
		--		INNER JOIN	Products.TechSize ts
		--			ON	ts.ts_id = mrd.ts_id
		--WHERE	mrd.doc_type_id = 1
		--		AND	mrd.quantity != 0
		--		AND	mrd.realizationreport_id = @realizationreport_id
		--ORDER BY
		--	mrd.rrd_id DESC