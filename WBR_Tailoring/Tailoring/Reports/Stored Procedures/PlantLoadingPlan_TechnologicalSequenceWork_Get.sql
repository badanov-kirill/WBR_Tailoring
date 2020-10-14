CREATE PROCEDURE [Reports].[PlantLoadingPlan_TechnologicalSequenceWork_Get]
	@start_dt DATE,
	@finish_dt DATE,
	@office_id INT,
	@equipment_id INT = NULL
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	CAST(c.calendar_date AS DATETIME) calendar_date,
			ISNULL(oaw.job_work_time, 0) / 3600 job_work_time,
			ISNULL(oat.table_work_time, 0) table_work_time
	FROM	RefBook.Calendar c   
			OUTER APPLY (
			      	SELECT	SUM(plptsw.work_time) job_work_time
			      	FROM	Planing.PlantLoadingPlan_TechnologicalSequenceWork plptsw   
			      			INNER JOIN	Planing.PlantLoadingPlan_TechnologicalSequence plpts
			      				ON	plpts.plpts_id = plptsw.plpts_id   
			      	WHERE	plptsw.work_dt = c.calendar_date
			      			AND	plptsw.office_id = @office_id
			      			AND (@equipment_id IS NULL OR plpts.equipment_id = @equipment_id)
			      ) oaw
	OUTER APPLY (
	      	SELECT	SUM(et.work_time) table_work_time
	      	FROM	Planing.EmployeeTable et   
	      			INNER JOIN	Settings.EmployeeSetting es
	      				ON	es.employee_id = et.work_employee_id
	      	WHERE	es.office_id = @office_id
	      			AND	et.work_dt = c.calendar_date
	      			AND	(
	      			   		@equipment_id IS NULL
	      			   		OR EXISTS (
	      			   		   	SELECT	1
	      			   		   	FROM	Settings.EmployeeEquipment ee
	      			   		   	WHERE	ee.employee_id = et.work_employee_id
	      			   		   			AND	ee.equipment_id = @equipment_id
	      			   		   )
	      			   	)
	      ) oat
	WHERE	c.calendar_date >= @start_dt
			AND	c.calendar_date <= @finish_dt
			