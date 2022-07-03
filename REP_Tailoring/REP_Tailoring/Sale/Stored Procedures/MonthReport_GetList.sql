CREATE PROCEDURE [Sale].[MonthReport_GetList]
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	mr.realizationreport_id,
			CAST(mr.period_dt AS DATETIME) period_dt,
			CAST(mr.period_to_dt AS DATETIME) period_to_dt
	FROM	Sale.MonthReport mr
	ORDER BY mr.period_dt DESC, mr.realizationreport_id DESC