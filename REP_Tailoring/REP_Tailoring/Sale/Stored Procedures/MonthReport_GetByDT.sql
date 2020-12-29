CREATE PROCEDURE [Sale].[MonthReport_GetByDT]
	@period_dt DATE
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	mr.realizationreport_id,
			CAST(mr.period_dt AS DATETIME) period_dt
	FROM	Sale.MonthReport mr
	WHERE	mr.period_dt = @period_dt