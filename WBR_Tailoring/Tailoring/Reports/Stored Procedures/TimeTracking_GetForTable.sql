CREATE PROCEDURE [Reports].[TimeTracking_GetForTable]
	@department_id INT = NULL,
	@start_dt DATE,
	@finish_dt DATE
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	
	
	;WITH cte AS (
		SELECT	ds.department_id,
				ds.department_name,
				ds.parrent_department_id,
				1 lvl
		FROM	Settings.DepartmentSetting ds
		WHERE	(ds.department_id = @department_id OR (@department_id IS NULL AND ds.parrent_department_id IS NULL))
		UNION ALL
		SELECT	ds.department_id,
				ds.department_name,
				ds.parrent_department_id,
				c.lvl + 1
		FROM	Settings.DepartmentSetting ds   
				INNER JOIN	cte c
					ON	ds.parrent_department_id = c.department_id
	),
	cte2 AS (
		SELECT	c.department_id,
				c.department_name,
				c.parrent_department_id,
				c.lvl,
				ISNULL(oad.count_cdep, 0) count_cdep,
				ISNULL(oae.count_cemp, 0) count_cemp
		FROM	cte c   
				OUTER APPLY (
				      	SELECT	COUNT(1) count_cdep
				      	FROM	Settings.DepartmentSetting ds
				      	WHERE	ds.parrent_department_id = c.department_id
				      ) oad
		OUTER APPLY (
		      	SELECT	COUNT(1) count_cemp
		      	FROM	Settings.EmployeeSetting es
		      	WHERE	es.department_id = c.department_id
		      			AND	es.is_work = 1
		      ) oae
	)
	,
	cte3 AS (
		SELECT	c.department_id,
				c.department_name,
				c.parrent_department_id,
				c.count_cemp,
				c.lvl
		FROM	cte2 c
		WHERE	c.count_cdep = 0 
		UNION ALL
		SELECT	c2.department_id,
				c2.department_name,
				c2.parrent_department_id,
				c2.count_cemp + c3.count_cemp,
				c2.lvl
		FROM	cte2 c2   
				INNER JOIN	cte3 c3
					ON	c3.parrent_department_id = c2.department_id
	)
	SELECT	c.department_id,
			c.department_name,
			c.parrent_department_id,
			SUM(c.count_cemp) count_cemp,
			c.lvl
	INTO	#t
	FROM	cte3 c
	GROUP BY
		c.department_id,
		c.department_name,
		c.parrent_department_id,
		c.lvl
	ORDER BY
		c.lvl,
		c.department_id
	
	SELECT	c.department_id,
			c.department_name,
			c.parrent_department_id,
			c.lvl
	FROM	#t c
	WHERE	c.count_cemp > 0
	
	SELECT	es.employee_id,
			es.employee_name,
			es.department_id
	FROM	Settings.EmployeeSetting es
	WHERE	EXISTS (
	     		SELECT	1
	     		FROM	#t c
	     		WHERE	c.department_id = es.department_id
	     	)
			AND	es.is_work = 1
	
	SELECT	CAST(et.tt_dt AS DATETIME)     work_dt,
			et.tt_employee_id              work_employee_id,
			SUM(CASE WHEN et.tt_state_id = 1 THEN et.tt_hour ELSE 0 END) time1,
			SUM(CASE WHEN et.tt_state_id = 2 THEN et.tt_hour ELSE 0 END) time2,
			SUM(CASE WHEN et.tt_state_id = 3 THEN et.tt_hour ELSE 0 END) time3,
			SUM(CASE WHEN et.tt_state_id = 4 THEN et.tt_hour ELSE 0 END) time4
	FROM	Reports.TimeTracking           et
	WHERE	EXISTS(
	     		SELECT	1
	     		FROM	Settings.EmployeeSetting es
	     		WHERE	EXISTS (
	     		     		SELECT	1
	     		     		FROM	#t c
	     		     		WHERE	c.department_id = es.department_id
	     		     	)
	     				AND	es.employee_id = et.tt_employee_id
	     	)
			AND	et.tt_dt >= @start_dt
			AND	et.tt_dt <= @finish_dt
	GROUP BY
		et.tt_dt,
		tt_employee_id
		
	SELECT	CAST(d.dt AS DATETIME)     work_dt,
			ttod.ttod_employee_id work_employee_id,
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
			END                        od3,
			CASE 
			     WHEN ttod.tt_state_id = 4 THEN ttod.ttod_type_id
			     ELSE 0
			END                        od4
	FROM	Reports.TimeTrackingOtherDay ttod   
			INNER JOIN	dbo.[Days] d
				ON	ttod.ttod_start_dt <= d.dt
				AND	ttod.ttod_finish_dt >= d.dt
	WHERE	d.dt >= @start_dt
			AND	d.dt <= @finish_dt
			AND EXISTS(
	     		SELECT	1
	     		FROM	Settings.EmployeeSetting es
	     		WHERE	EXISTS (
	     		     		SELECT	1
	     		     		FROM	#t c
	     		     		WHERE	c.department_id = es.department_id
	     		     	)
	     				AND	es.employee_id = ttod.ttod_employee_id
	     	)
	ORDER BY
		d.dt,
		ttod.tt_state_id,
		ttod.ttod_type_id
	
	DROP TABLE #t