CREATE PROCEDURE [Reports].[TimeTracking_GetTableForEmployee]
	@employee_id INT = NULL,
	@start_dt DATE,
	@finish_dt DATE
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	CAST(et.tt_dt AS DATETIME)     work_dt,
			et.tt_employee_id              work_employee_id,
			SUM(CASE WHEN et.tt_state_id = 1 THEN et.tt_hour ELSE 0 END) time1,
			SUM(CASE WHEN et.tt_state_id = 2 THEN et.tt_hour ELSE 0 END) time2,
			SUM(CASE WHEN et.tt_state_id = 3 THEN et.tt_hour ELSE 0 END) time3
	FROM	Reports.TimeTracking           et
	WHERE	et.tt_dt >= @start_dt
			AND	et.tt_dt <= @finish_dt
			AND	(@employee_id IS NULL OR et.tt_employee_id = @employee_id)
			AND et.tt_state_id IN (1,2,3)
	GROUP BY
		et.tt_dt,
		tt_employee_id
	
	SELECT	CAST(d.dt AS DATETIME)     dt,
			CASE 
			     WHEN ttod.tt_state_id = 1 THEN ttod.ttod_type_id
			     ELSE 0
			END                        od1,
			CASE 
			     WHEN ttod.tt_state_id = 2 THEN ttod.ttod_type_id
			     ELSE 0
			END                        od2,
			CASE 
			     WHEN ttod.tt_state_id = 3 THEN ttod.ttod_type_id
			     ELSE 0
			END                        od3
	FROM	Reports.TimeTrackingOtherDay ttod   
			INNER JOIN	dbo.[Days] d
				ON	ttod.ttod_start_dt <= d.dt
				AND	ttod.ttod_finish_dt >= d.dt
	WHERE	d.dt >= @start_dt
			AND	d.dt <= @finish_dt
			AND	ttod.ttod_employee_id = @employee_id
			AND ttod.tt_state_id IN (1,2,3)
	ORDER BY
		d.dt,
		ttod.tt_state_id,
		ttod.ttod_type_id