CREATE PROCEDURE [Sale].[MonthRedortDetail_Return_GetByID_v2]
@realizationreport_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	DENSE_RANK() OVER(ORDER BY v.realizationreport_id ASC, DATEADD(DAY, 1, EOMONTH(v.sale_dt, -1)) ASC) AS doc_index,
			v.realizationreport_id,
			CAST(DATEADD(DAY, 1, EOMONTH(v.sale_dt, -1)) AS DATETIME) sale_period_dt,
			v.sale_dt,
			sa.sa_name,
			mrd.quantity,
			mrd.nds,
			mrd.retail_amount
	FROM	sale.MonthReportDetail mrd   
			INNER JOIN	sale.MonthReport mr0
				ON	mr0.realizationreport_id = mrd.realizationreport_id  
			INNER JOIN	products.SupplierArticle sa
				ON	sa.sa_id = mrd.sa_id   
			OUTER APPLY (
			      	SELECT	TOP(1) mrds.realizationreport_id,
			      			CASE 
			      			     WHEN mrds.sale_dt >= mrs.period_dt AND mrds.sale_dt <= mrs.period_to_dt THEN mrds.sale_dt
			      			     ELSE mrs.period_dt
			      			END             sale_dt,
			      			mrds.rrd_id     rrd_id
			      	FROM	sale.MonthReportDetail mrds   
			      			INNER JOIN	Sale.MonthReport mrs
			      				ON	mrs.realizationreport_id = mrds.realizationreport_id
			      	WHERE	mrds.doc_type_id = 1
			      			AND	mrds.quantity != 0
			      			AND	mrds.sale_dt = mrd.sale_dt
			      			AND	mrds.shk_id = mrd.shk_id
			      	ORDER BY
			      		mrds.realizationreport_id,
			      		mrds.rrd_id
			      ) v	
			 
			OUTER APPLY (
			      	SELECT	TOP(1) mrdr.rrd_id rrd_id
			      	FROM	sale.MonthReportDetail mrdr
			      	WHERE	mrdr.doc_type_id = 2
			      			AND	mrdr.quantity != 0
			      			AND	mrdr.sale_dt = mrd.sale_dt
			      			AND	mrdr.shk_id = mrd.shk_id
			      	ORDER BY
			      		mrdr.realizationreport_id,
			      		mrdr.rrd_id
			      ) v2
	WHERE	mrd.doc_type_id = 2
			AND	mrd.quantity != 0
			AND	mrd.realizationreport_id = @realizationreport_id
			AND	v2.rrd_id = mrd.rrd_id
	ORDER BY
		v.realizationreport_id,
		v.sale_dt,
		mrd.rrd_id