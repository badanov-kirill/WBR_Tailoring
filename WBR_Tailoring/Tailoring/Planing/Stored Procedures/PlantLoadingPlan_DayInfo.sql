CREATE PROCEDURE [Planing].[PlantLoadingPlan_DayInfo]
	@dt DATE
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	ve.office_id,
			ve.employee_id,
			ve.employee_name,
			ve.brigade_id,
			ve.work_time - ISNULL(vj.job_second, 0) work_time
	FROM	(SELECT	et.work_employee_id employee_id,
					es.employee_name,
	    	 		es.office_id,
	    	 		es.brigade_id,
	    	 		SUM(et.work_time) * 3600 work_time
	    	 FROM	Planing.EmployeeTable et   
	    	 		INNER JOIN	Settings.EmployeeSetting es
	    	 			ON	es.employee_id = et.work_employee_id
	    	 WHERE	et.work_dt = @dt
	    	 GROUP BY
	    	 	et.work_employee_id,
	    	 	es.employee_name,
	    	 	es.office_id,
				es.brigade_id)ve   
			LEFT JOIN	(SELECT	SUM(plptsw.work_time) job_second,
			    	    	 		plptsw.employee_id
			    	    	 FROM	Planing.PlantLoadingPlan_TechnologicalSequenceWork plptsw
			    	    	 WHERE	plptsw.work_dt = @dt
			    	    	 GROUP BY
			    	    	 	plptsw.employee_id)vj
				ON	ve.employee_id = vj.employee_id
	WHERE	ve.work_time > ISNULL(vj.job_second, 0)
