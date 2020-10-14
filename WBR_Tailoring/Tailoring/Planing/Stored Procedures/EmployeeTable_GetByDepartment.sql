CREATE PROCEDURE [Planing].[EmployeeTable_GetByDepartment]
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
			oa.eq_cnt,
			es.brigade_id, 
			b.brigade_name
	FROM	Settings.EmployeeSetting es  
			LEFT JOIN Settings.Brigade b 
				ON b.brigade_id = es.brigade_id 
			OUTER APPLY (
			      	SELECT	COUNT(1) eq_cnt
			      	FROM	Settings.EmployeeEquipment ee
			      	WHERE	ee.employee_id = es.employee_id
			      ) oa
	WHERE	EXISTS (
	     		SELECT	1
	     		FROM	#t c
	     		WHERE	c.department_id = es.department_id
	     	)
	
	SELECT	CAST(et.work_dt AS DATETIME)     work_dt,
			et.work_employee_id,
			et.work_time
	FROM	Planing.EmployeeTable            et
	WHERE	EXISTS(
	     		SELECT	1
	     		FROM	Settings.EmployeeSetting es
	     		WHERE	EXISTS (
	     		     		SELECT	1
	     		     		FROM	#t c
	     		     		WHERE	c.department_id = es.department_id
	     			)
	     			AND es.employee_id = et.work_employee_id
	     	)
			AND	et.work_dt >= @start_dt
			AND	et.work_dt <= @finish_dt
	
	DROP TABLE #t