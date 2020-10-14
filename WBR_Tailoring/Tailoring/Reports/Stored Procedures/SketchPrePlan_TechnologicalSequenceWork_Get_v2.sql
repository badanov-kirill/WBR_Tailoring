CREATE PROCEDURE [Reports].[SketchPrePlan_TechnologicalSequenceWork_Get_v2]
	@start_dt DATE,
	@finish_dt DATE,
	@office_id INT,
	@equipment_id INT = NULL
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	CAST(c.calendar_date AS DATETIME) calendar_date,
			ew.equipment_id,
			CASE 
			     WHEN ISNULL(oat.table_work_time, 0) < ew.equipment_time THEN ISNULL(oat.table_work_time, 0)
			     ELSE ew.equipment_time
			END     equipment_time,
			ISNULL(CAST(oaw.job_work_time AS DECIMAL(9, 2)), 0) / 3600 job_work_time,
			ISNULL(oat.table_work_time, 0) table_work_time
	FROM	RefBook.Calendar c   
			CROSS JOIN	(SELECT	we.equipment_id,
			    	     	 		SUM(we.work_hour) equipment_time
			    	     	 FROM	Manufactory.WorkshopEquipment we   
			    	     	 		INNER JOIN	Warehouse.ZoneOfResponse zor
			    	     	 			ON	zor.zor_id = we.zor_id
			    	     	 WHERE	zor.office_id = @office_id
			    	     	 		AND	we.is_deleted = 0
			    	     	 		AND	(@equipment_id IS NULL OR we.equipment_id = @equipment_id)
			    	     	 GROUP BY
			    	     	 	we.equipment_id)ew   
			OUTER APPLY (
			      	SELECT	SUM(spptsw.work_time) job_work_time
			      	FROM	Planing.SketchPrePlan_TechnologicalSequenceWork spptsw   
			      			INNER JOIN	Planing.SketchPrePlan_TechnologicalSequence sppts
			      				ON	sppts.sppts_id = spptsw.sppts_id   
			      			INNER JOIN	Planing.SketchPrePlan spp
			      				ON	spp.spp_id = sppts.spp_id
			      	WHERE	spptsw.work_dt = c.calendar_date
			      			AND	spp.sew_office_id = @office_id
			      			AND	ew.equipment_id = sppts.equipment_id
			      ) oaw
	OUTER APPLY (
	      	SELECT	SUM(et.work_time) table_work_time
	      	FROM	Planing.EmployeeTable et   
	      			INNER JOIN	Settings.EmployeeSetting es
	      				ON	es.employee_id = et.work_employee_id
	      	WHERE	es.office_id = @office_id
	      			AND	et.work_dt = c.calendar_date
	      )         oat
	WHERE	c.calendar_date >= @start_dt
			AND	c.calendar_date <= @finish_dt
	ORDER BY
		c.calendar_date,
		ew.equipment_id