CREATE PROCEDURE [Planing].[PlantLoadingPlan_GetBrigade]
	@office_id INT,
	@dt DATE
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET ARITHABORT ON
	
	DECLARE @finish_dt DATE = DATEADD(DAY, 30, @dt)
	
	SELECT	TOP(1) es.brigade_id
	FROM	RefBook.Calendar c   
			CROSS JOIN	Settings.EmployeeSetting es   
			LEFT JOIN	Planing.EmployeeTable et
				ON	c.calendar_date = et.work_dt
				AND	et.work_employee_id = es.employee_id   
			LEFT JOIN	(SELECT	plptsw.work_dt,
			    	    	 		plptsw.employee_id,
			    	    	 		CAST(SUM(plptsw.work_time) AS DECIMAL(15, 2)) / 3600 job_time
			    	    	 FROM	Planing.PlantLoadingPlan_TechnologicalSequenceWork plptsw
			    	    	 GROUP BY
			    	    	 	plptsw.work_dt,
			    	    	 	plptsw.employee_id)v
				ON	c.calendar_date = v.work_dt
				AND	v.employee_id = es.employee_id
	WHERE	es.office_id = @office_id
			AND	es.brigade_id IS NOT NULL
			AND	c.calendar_date >= @dt
			AND	c.calendar_date <= @finish_dt
			AND	EXISTS(
			   		SELECT	1
			   		FROM	Settings.EmployeeEquipment ee
			   		WHERE	ee.employee_id = es.employee_id
			   	)
	GROUP BY
		es.brigade_id
	ORDER BY
		(SUM(et.work_time) - SUM(v.job_time)) / SUM(et.work_time) DESC