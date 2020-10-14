CREATE PROCEDURE [Reports].[SketchPrePlan_TechnologicalSequenceWork_Get_v1]
	@start_dt DATE,
	@finish_dt DATE,
	@office_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	CAST(c.calendar_date AS DATETIME) calendar_date,
			ISNULL(oaw.job_work_time, 0) / 3600 job_work_time,
			ISNULL(oat.table_work_time, 0) table_work_time
	FROM	RefBook.Calendar c   
			OUTER APPLY (
			      	SELECT	SUM(spptsw.work_time) job_work_time
			      	FROM	Planing.SketchPrePlan_TechnologicalSequenceWork spptsw   
			      			INNER JOIN	Planing.SketchPrePlan_TechnologicalSequence sppts
			      				ON	sppts.sppts_id = spptsw.sppts_id   
			      			INNER JOIN	Planing.SketchPrePlan spp
			      				ON	spp.spp_id = sppts.spp_id
			      	WHERE	spptsw.work_dt = c.calendar_date
			      			AND	spp.sew_office_id = @office_id
			      ) oaw
	OUTER APPLY (
	      	SELECT	SUM(et.work_time) table_work_time
	      	FROM	Planing.EmployeeTable et   
	      			INNER JOIN	Settings.EmployeeSetting es
	      				ON	es.employee_id = et.work_employee_id
	      	WHERE	es.office_id = @office_id
	      			AND	et.work_dt = c.calendar_date
	      ) oat
	WHERE	c.calendar_date >= @start_dt
			AND	c.calendar_date <= @finish_dt
			