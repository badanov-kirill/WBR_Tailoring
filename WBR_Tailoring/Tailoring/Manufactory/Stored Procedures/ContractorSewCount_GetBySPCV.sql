CREATE PROCEDURE [Manufactory].[ContractorSewCount_GetBySPCV]
	@spcv_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	ts.ts_name,
			csc.cnt,
			es.employee_name,
			CAST(csc.dt AS DATETIME) dt
	FROM	Manufactory.ContractorSewCount csc   
			INNER JOIN	Planing.SketchPlanColorVariantTS spcvt
				ON	spcvt.spcvts_id = csc.spcvts_id   
			INNER JOIN	Products.TechSize ts
				ON	ts.ts_id = spcvt.ts_id   
			LEFT JOIN	Settings.EmployeeSetting es
				ON	es.employee_id = csc.employee_id
	WHERE	spcvt.spcv_id = @spcv_id
	ORDER BY
		es.dt,
		ts.visible_queue,
		ts_name