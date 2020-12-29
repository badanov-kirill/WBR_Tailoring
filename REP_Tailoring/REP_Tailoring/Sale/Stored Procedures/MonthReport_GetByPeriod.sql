CREATE PROCEDURE [Sale].[MonthReport_GetByPeriod]
	@start_dt DATE,
	@finish_dt DATE
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	mr.realizationreport_id,
			CAST(mr.period_dt AS DATETIME) period_dt,
			CAST(mr.period_to_dt AS DATETIME) period_to_dt
	FROM	Sale.MonthReport mr
	WHERE	mr.period_dt >= @start_dt
			AND	mr.period_to_dt <= @finish_dt