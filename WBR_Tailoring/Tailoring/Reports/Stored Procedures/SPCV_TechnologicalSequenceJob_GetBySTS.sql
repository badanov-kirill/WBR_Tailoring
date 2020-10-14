CREATE PROCEDURE [Reports].[SPCV_TechnologicalSequenceJob_GetBySTS]
	@sts_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	ts.ts_name,
			es.employee_name,
			stsj.plan_cnt,
			CAST(stsj.dt AS DATETIME) dt,
			stsj.employee_cnt,
			stsj.close_cnt,
			CAST(stsj.close_dt AS DATETIME) close_dt,
			CAST(stsj.salary_close_dt AS DATETIME) salary_close_dt,
			vs.operation_salary,
			vs.amount_salary,
			stsj.stsj_id
	FROM	Manufactory.SPCV_TechnologicalSequenceJob stsj   
			INNER JOIN	Planing.SketchPlanColorVariantTS spcvt
				ON	spcvt.spcvts_id = stsj.spcvts_id   
			INNER JOIN	Products.TechSize ts
				ON	ts.ts_id = spcvt.ts_id   
			LEFT JOIN	Settings.EmployeeSetting es
				ON	es.employee_id = stsj.job_employee_id   
			LEFT JOIN	(SELECT	stsjis.stsj_id,
			    	    	 		SUM(stsjis.cnt) operation_salary,
			    	    	 		SUM(stsjis.amount) amount_salary
			    	    	 FROM	Manufactory.SPCV_TechnologicalSequenceJobInSalary stsjis
			    	    	 GROUP BY
			    	    	 	stsjis.stsj_id)vs
				ON	vs.stsj_id = stsj.stsj_id
	WHERE	stsj.sts_id = @sts_id
