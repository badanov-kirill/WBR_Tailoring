CREATE PROCEDURE [Planing].[PlantLoadingPlan_EmployeeTable]
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
	)
	SELECT	c.department_id,
			c.department_name,
			c.parrent_department_id,
			c.lvl
	INTO	#t
	FROM	cte c
	
	SELECT	c.department_id,
			c.department_name,
			c.parrent_department_id,
			c.lvl
	FROM	#t c
	
	SELECT	es.employee_id,
			es.employee_name,
			es.department_id,
			es.brigade_id, 
			b.brigade_name
	FROM	Settings.EmployeeSetting es  
			LEFT JOIN Settings.Brigade b 
				ON b.brigade_id = es.brigade_id 
			
	WHERE	EXISTS (
	     		SELECT	1
	     		FROM	#t c
	     		WHERE	c.department_id = es.department_id
	     	)
	
	SELECT	CAST(c.calendar_date AS DATETIME)     work_dt,
			es.employee_id work_employee_id,
			et.work_time,
			v.job_time
	FROM RefBook.Calendar c
	CROSS JOIN 	Settings.EmployeeSetting es
	LEFT JOIN Planing.EmployeeTable            et ON c.calendar_date = et.work_dt AND et.work_employee_id = es.employee_id
	LEFT JOIN (SELECT plptsw.work_dt, plptsw.employee_id, cast(sum(plptsw.work_time) AS DECIMAL(15,2)) / 3600 job_time
	             FROM Planing.PlantLoadingPlan_TechnologicalSequenceWork            plptsw
	           GROUP BY plptsw.work_dt, plptsw.employee_id			
	) v ON c.calendar_date = v.work_dt AND v.employee_id = es.employee_id
	WHERE	EXISTS (
	     		     		SELECT	1
	     		     		FROM	#t c
	     		     		WHERE	c.department_id = es.department_id
	     		     	)
			AND	c.calendar_date >= @start_dt
			AND	c.calendar_date <= @finish_dt
	
	DROP TABLE #t