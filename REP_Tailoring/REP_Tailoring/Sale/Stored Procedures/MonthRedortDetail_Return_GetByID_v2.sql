CREATE PROCEDURE [Sale].[MonthRedortDetail_Return_GetByID_v2]
	@realizationreport_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	DENSE_RANK() OVER(
	      		ORDER BY v.realizationreport_id ASC,
	      		DATEADD(DAY, 1, EOMONTH(v.sale_dt, -1)) 
	      		ASC
	      	)                             AS doc_index,
			v.realizationreport_id,
			CAST(DATEADD(DAY, 1, EOMONTH(v.sale_dt, -1)) AS DATETIME) sale_period_dt,
			v.sale_dt,
			sa.sa_name,
			mrd.quantity,
			mrd.nds,
			mrd.retail_amount
	FROM	Sale.MonthReportDetail mrd   
			INNER JOIN	Sale.MonthReport mr0
				ON	mr0.realizationreport_id = mrd.realizationreport_id   
			OUTER APPLY	(SELECT TOP(1)	mrds.realizationreport_id,
			    	    	 		CASE WHEN mrds.sale_dt >= mrs.period_dt AND mrds.sale_dt <= mrs.period_to_dt THEN mrds.sale_dt ELSE mrs.period_dt END sale_dt,
			    	    	 		mrds.rrd_id rrd_id
			    	    	 FROM	Sale.MonthReportDetail mrds
			    	    	 INNER JOIN Sale.MonthReport mrs ON mrs.realizationreport_id = mrds.realizationreport_id
			    	    	 WHERE	mrds.doc_type_id = 1
			    	    	 		AND	mrds.quantity != 0
			    	    	 		AND mrds.sale_dt = mrd.sale_dt
									AND	mrds.shk_id = mrd.shk_id  
			    	    	 
			           	 ORDER BY mrds.realizationreport_id, mrds.rrd_id
			) 	    	 	v
			 
			INNER JOIN	Products.SupplierArticle sa
				ON	sa.sa_id = mrd.sa_id   
			INNER JOIN	(SELECT	mrds.shk_id,
			    	     	 		mrds.sale_dt,
			    	     	 		MIN(mrds.rrd_id) rrd_id
			    	     	 FROM	Sale.MonthReportDetail mrds
			    	     	 WHERE	mrds.doc_type_id = 2
			    	     	 		AND	mrds.quantity != 0
			    	     	 GROUP BY
			    	     	 	mrds.shk_id,
			    	     	 	mrds.sale_dt)v2
				ON	v2.sale_dt = mrd.sale_dt
				AND	v2.shk_id = mrd.shk_id
				AND	v2.rrd_id = mrd.rrd_id
	WHERE	mrd.doc_type_id = 2
			AND	mrd.quantity != 0
			AND	mrd.realizationreport_id = @realizationreport_id
	ORDER BY
		v.realizationreport_id,
		v.sale_dt,
		mrd.rrd_id