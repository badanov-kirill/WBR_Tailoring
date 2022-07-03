CREATE PROCEDURE [Sale].[MonthReport_GetByPeriod]
	@start_dt DATE,
	@finish_dt DATE
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	mr.realizationreport_id,
			CAST(mr.period_dt AS DATETIME) period_dt,
			CAST(mr.period_to_dt AS DATETIME) period_to_dt,
			oa_sc.site_country
	FROM	Sale.MonthReport mr   
			OUTER APPLY (
			      	SELECT	string_agg(v.site_country, ';') site_country
			      	FROM	(SELECT	DISTINCT mrd.site_country
			      	    	 FROM	Sale.MonthReportDetail mrd
			      	    	 WHERE	mrd.realizationreport_id = mr.realizationreport_id)v
			      ) oa_sc
	WHERE	mr.period_dt >= @start_dt
			AND	mr.period_to_dt <= @finish_dt