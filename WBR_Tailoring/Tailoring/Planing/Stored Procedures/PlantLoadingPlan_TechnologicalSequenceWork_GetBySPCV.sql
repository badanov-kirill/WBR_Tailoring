CREATE PROCEDURE [Planing].[PlantLoadingPlan_TechnologicalSequenceWork_GetBySPCV]
	@spcv_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	CAST(plptsw.work_dt AS DATETIME) work_dt,
			plpts.operation_range,
			e.equipment_name,
			CAST(plptsw.work_time AS DECIMAL(15, 2)) / 3600 work_hour,
			plptsw.plpts_id id,
			plptsw.office_id,
			plptsw.work_time,
			es.employee_name
	FROM	Planing.PlantLoadingPlan_TechnologicalSequenceWork plptsw   
			INNER JOIN	Planing.PlantLoadingPlan_TechnologicalSequence plpts
				ON	plpts.plpts_id = plptsw.plpts_id   
			INNER JOIN	Technology.Equipment e
				ON	e.equipment_id = plpts.equipment_id
			LEFT JOIN Settings.EmployeeSetting es
				ON es.employee_id = plptsw.employee_id
	WHERE	plpts.spcv_id = @spcv_id
	ORDER BY plpts.operation_range, plptsw.work_dt