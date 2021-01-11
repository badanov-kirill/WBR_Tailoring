CREATE PROCEDURE [Sale].[MonthRedortDetail_Return_GetByID_v3]
	@realizationreport_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	mrd.rrd_id,
			mrd.shk_id,
			CAST(mrd.sale_dt AS DATETIME) sale_dt,
			sa.sa_name,
			mrd.quantity,
			mrd.nds,
			mrd.retail_amount
	FROM	sale.MonthReportDetail mrd   
			INNER JOIN	Products.SupplierArticle sa
				ON	sa.sa_id = mrd.sa_id
	WHERE	mrd.doc_type_id = 2
			AND	mrd.quantity != 0
			AND	mrd.realizationreport_id = @realizationreport_id
	ORDER BY
		mrd.rrd_id
	
	SELECT	mrd.rrd_id,
			DENSE_RANK() OVER(ORDER BY mrds.realizationreport_id ASC, DATEADD(DAY, 1, EOMONTH((CASE WHEN mrds.sale_dt >= mrs.period_dt AND mrds.sale_dt <= mrs.period_to_dt THEN mrds.sale_dt ELSE mrs.period_dt END), -1))  ASC) AS doc_index,
			mrds.realizationreport_id,
			CAST(
				DATEADD(DAY, 1, EOMONTH((CASE WHEN mrds.sale_dt >= mrs.period_dt AND mrds.sale_dt <= mrs.period_to_dt THEN mrds.sale_dt ELSE mrs.period_dt END), -1)) 
				AS DATETIME
			) sale_period_dt,
			sa.sa_name,
			mrds.retail_amount
	FROM	sale.MonthReportDetail mrd   
			INNER JOIN	Products.SupplierArticle sa
				ON	sa.sa_id = mrd.sa_id   
			INNER JOIN	sale.MonthReportDetail mrds
				ON	mrds.sale_dt = mrd.sale_dt
				AND	mrds.shk_id = mrd.shk_id
				AND	mrds.doc_type_id = 1
				AND	mrds.quantity != 0   
			INNER JOIN	sale.MonthReport mrs
				ON	mrs.realizationreport_id = mrds.realizationreport_id
	WHERE	mrd.doc_type_id = 2
			AND	mrd.quantity != 0
			AND	mrd.realizationreport_id = @realizationreport_id
	ORDER BY
		mrd.rrd_id