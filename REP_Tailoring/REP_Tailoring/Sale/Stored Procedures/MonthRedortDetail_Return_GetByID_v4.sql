CREATE PROCEDURE [Sale].[MonthRedortDetail_Return_GetByID_v4]
	@realizationreport_id INT
AS
BEGIN
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	MIN(mrd.rrd_id)            rrd_id,
			mrd.shk_id,
			MIN(CAST(mrd.sale_dt AS DATETIME)) sale_dt,
			sa.sa_name,
			1                          quantity,
			MIN(mrd.nds)               nds,
			SUM(mrd.retail_amount)     retail_amount,
			mrd.realizationreport_id
	INTO	#t
	FROM	Sale.MonthReportDetail mrd   
			INNER JOIN	Products.SupplierArticle sa
				ON	sa.sa_id = mrd.sa_id
	WHERE	mrd.doc_type_id = 2
			AND	mrd.quantity != 0
			AND	mrd.retail_amount != 0
			AND	mrd.realizationreport_id = @realizationreport_id
	GROUP BY
		mrd.shk_id,
		sa.sa_name,
		mrd.realizationreport_id
	ORDER BY
		rrd_id
	
	SELECT	*
	FROM	#t t
	
	SELECT	mrd.rrd_id,
			DENSE_RANK() OVER(
				ORDER BY oamrds.realizationreport_id ASC,
				DATEADD(DAY, 1, EOMONTH((CASE WHEN oamrds.sale_dt >= mrs.period_dt AND oamrds.sale_dt <= mrs.period_to_dt THEN oamrds.sale_dt ELSE mrs.period_dt END), -1)) 
				ASC
			)  AS doc_index,
			oamrds.realizationreport_id,
			CAST(
				DATEADD(DAY, 1, EOMONTH((CASE WHEN oamrds.sale_dt >= mrs.period_dt AND oamrds.sale_dt <= mrs.period_to_dt THEN oamrds.sale_dt ELSE mrs.period_dt END), -1)) 
				AS DATETIME
			)     sale_period_dt,
			mrd.sa_name,
			oamrdsa.retail_amount
	FROM	#t mrd   
			OUTER APPLY (
			      	SELECT	TOP(1) mrds.realizationreport_id,
			      			mrds.sale_dt,
			      			mrds.shk_id
			      	FROM	Sale.MonthReportDetail mrds
			      	WHERE	
			      			mrds.shk_id = mrd.shk_id
			      			AND	mrds.doc_type_id = 1
			      			AND	mrds.quantity != 0
			      			AND mrds.retail_amount != 0
			      			AND mrds.realizationreport_id <= mrd.realizationreport_id
			      	ORDER BY
			      	IIF(mrds.sale_dt = mrd.sale_dt, 0,1) asc,
			      		mrds.realizationreport_id DESC
			      ) oamrds 
	OUTER APPLY (
	      	SELECT	SUM(mrds.retail_amount) retail_amount
	      	FROM	Sale.MonthReportDetail mrds
	      	WHERE	
	      				mrds.shk_id = mrd.shk_id
	      			AND	mrds.doc_type_id = 1
	      			AND	mrds.quantity != 0
	      			AND mrds.retail_amount != 0
	      			AND	mrds.realizationreport_id = oamrds.realizationreport_id	      	
	      ) oamrdsa 
	INNER JOIN	Sale.MonthReport mrs
				ON	mrs.realizationreport_id = oamrds.realizationreport_id
	ORDER BY
		mrd.rrd_id
		
		DROP TABLE IF EXISTS #t
		
		--		SELECT	mrd.rrd_id,
		--		mrd.shk_id,
		--		CAST(mrd.sale_dt AS DATETIME) sale_dt,
		--		sa.sa_name,
		--		mrd.quantity,
		--		mrd.nds,
		--		mrd.retail_amount
		--FROM	Sale.MonthReportDetail mrd
		--		INNER JOIN	Products.SupplierArticle sa
		--			ON	sa.sa_id = mrd.sa_id
		--WHERE	mrd.doc_type_id = 2
		--		AND	mrd.quantity != 0
		--		AND	mrd.realizationreport_id = @realizationreport_id
		--ORDER BY
		--	mrd.rrd_id
		
		--SELECT	mrd.rrd_id,
		--		DENSE_RANK() OVER(
		--			ORDER BY oamrds.realizationreport_id ASC,
		--			DATEADD(DAY, 1, EOMONTH((CASE WHEN oamrds.sale_dt >= mrs.period_dt AND oamrds.sale_dt <= mrs.period_to_dt THEN oamrds.sale_dt ELSE mrs.period_dt END), -1))
		--			ASC
		--		)  AS doc_index,
		--		oamrds.realizationreport_id,
		--		CAST(
		--			DATEADD(DAY, 1, EOMONTH((CASE WHEN oamrds.sale_dt >= mrs.period_dt AND oamrds.sale_dt <= mrs.period_to_dt THEN oamrds.sale_dt ELSE mrs.period_dt END), -1))
		--			AS DATETIME
		--		)     sale_period_dt,
		--		sa.sa_name,
		--		oamrds.retail_amount
		--FROM	Sale.MonthReportDetail mrd
		--		INNER JOIN	Products.SupplierArticle sa
		--			ON	sa.sa_id = mrd.sa_id
		--		OUTER APPLY (
		--		      	SELECT	TOP(1) mrds.realizationreport_id,
		--		      			mrds.sale_dt,
		--		      			mrds.retail_amount
		--		      	FROM	Sale.MonthReportDetail mrds
		--		      	WHERE	mrds.sale_dt = mrd.sale_dt
		--		      			AND	mrds.shk_id = mrd.shk_id
		--		      			AND	mrds.doc_type_id = 1
		--		      			AND	mrds.quantity != 0
		--		      	ORDER BY
		--		      		mrds.realizationreport_id DESC
		--		      ) oamrds
		--INNER JOIN	Sale.MonthReport mrs
		--			ON	mrs.realizationreport_id = oamrds.realizationreport_id
		--WHERE	mrd.doc_type_id = 2
		--		AND	mrd.quantity != 0
		--		AND	mrd.realizationreport_id = @realizationreport_id
		--ORDER BY
		--	mrd.rrd_id
END