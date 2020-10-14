CREATE PROCEDURE [Planing].[SketchPrePlan_DayInfo]
	@dt DATE,
	@start_dt DATE,
	@finish_dt DATE
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	ve.office_id,
			ve.work_time - ISNULL(vj.job_second, 0) work_time
	FROM	(SELECT	SUM(et.work_time) * 3600 work_time,
	    	 		es.office_id
	    	 FROM	Planing.EmployeeTable et   
	    	 		INNER JOIN	Settings.EmployeeSetting es
	    	 			ON	es.employee_id = et.work_employee_id
	    	 WHERE	et.work_dt = @dt
	    	 GROUP BY
	    	 	es.office_id)ve   
			LEFT JOIN	(SELECT	SUM(spptsw.work_time) job_second,
			    	    	 		spptsw.office_id
			    	    	 FROM	Planing.SketchPrePlan_TechnologicalSequenceWork spptsw   
			    	    	 		INNER JOIN	Planing.SketchPrePlan_TechnologicalSequence sppts
			    	    	 			ON	sppts.sppts_id = spptsw.sppts_id   
			    	    	 		INNER JOIN	Planing.SketchPrePlan spp
			    	    	 			ON	spp.spp_id = sppts.spp_id
			    	    	 WHERE	spptsw.work_dt = @dt
			    	    	 		AND	(spp.plan_dt > @finish_dt OR spp.plan_dt < @start_dt)
			    	    	 GROUP BY
			    	    	 	spptsw.office_id)vj
				ON	ve.office_id = vj.office_id
	WHERE ve.work_time - ISNULL(vj.job_second, 0) > 0
