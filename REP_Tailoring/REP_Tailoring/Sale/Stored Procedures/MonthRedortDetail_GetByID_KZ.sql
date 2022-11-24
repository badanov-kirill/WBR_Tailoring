CREATE PROCEDURE [Sale].[MonthRedortDetail_GetByID_KZ]
	@realizationreport_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	sa.sa_name,
			''                    ts_name,
			SUM(mrd.quantity)     quantity,
			mrd.nds,
			SUM(mrd.ppvz_for_pay - mrd.delivery_rub) retail_amount,
			CAST(MAX(mrd.sale_dt) AS DATETIME)
			sale_dt,
			CAST(MAX(mrd.sale_dt) AS DATETIME) sale_period_dt
	FROM	Sale.MonthReportDetail mrd   
			INNER JOIN	Sale.MonthReport mr
				ON	mr.realizationreport_id = mrd.realizationreport_id   
			INNER JOIN	Products.SupplierArticle sa
				ON	sa.sa_id = mrd.sa_id   
			INNER JOIN	Products.TechSize ts
				ON	ts.ts_id = mrd.ts_id
	WHERE	mrd.doc_type_id = 1
			AND	mrd.realizationreport_id = @realizationreport_id
	GROUP BY
		sa.sa_name,
		mrd.nds
	HAVING
		SUM(mrd.quantity) > 0
	
	
	