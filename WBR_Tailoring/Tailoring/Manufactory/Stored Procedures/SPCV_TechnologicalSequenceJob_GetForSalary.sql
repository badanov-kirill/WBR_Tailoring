CREATE PROCEDURE [Manufactory].[SPCV_TechnologicalSequenceJob_GetForSalary]
	@office_id INT = NULL
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	s.sketch_id,
			b.brand_name,
			pa.sa + pan.sa                sa,
			an.art_name,
			sj.subject_name,
			ts.ts_name,
			ta.ta_name                    ta,
			e.element_name                element,
			eq.equipment_name             equipment,
			sts.discharge_id,
			sts.operation_time,
			ISNULL(stsj.close_cnt, 0) close_cnt,
			CAST(stsj.dt AS DATETIME)     dt,
			stsj.stsj_id,
			spcv.spcv_id,
			stsj.sts_id,
			stsj.job_employee_id,
			es.employee_name,
			ds.department_name,
			os.office_name                employee_office_name,
			CASE 
			     WHEN sse.sketch_id IS NULL THEN ISNULL(ready.cnt_ready, 0) + ISNULL(ready_contr.sew_count, 0)
			     ELSE ISNULL(job_close.sum_close_cnt , 0)
			END cnt_ready,
			ISNULL(salary.cnt_salary, 0) cnt_salary,
			ROUND(stsjc.cost_per_hour * sts.operation_time / 3600, 6) cost_job,
			spcvt.spcvts_id,
			sts.operation_range,
			CASE 
			     WHEN sse.sketch_id IS NULL THEN ISNULL(salary2.cnt_salary, 0)
			     ELSE 0
			END cnt_salary2,
			ISNULL(job_close.sum_close_cnt , 0) sum_close_cnt
	FROM	Manufactory.SPCV_TechnologicalSequenceJob stsj   
			INNER JOIN	Manufactory.SPCV_TechnologicalSequence sts
				ON	sts.sts_id = stsj.sts_id   
			INNER JOIN	Planing.SketchPlanColorVariantTS spcvt
				ON	spcvt.spcvts_id = stsj.spcvts_id   
			INNER JOIN	Planing.SketchPlanColorVariant spcv
				ON	spcv.spcv_id = spcvt.spcv_id   
			INNER JOIN	Products.ProdArticleNomenclature pan
				ON	pan.pan_id = spcv.pan_id   
			INNER JOIN	Products.ProdArticle pa
				ON	pa.pa_id = pan.pa_id   
			INNER JOIN	Products.Sketch s
				ON	s.sketch_id = pa.sketch_id   
			INNER JOIN	Products.Brand b
				ON	b.brand_id = pa.brand_id   
			INNER JOIN	Products.[Subject] sj
				ON	sj.subject_id = s.subject_id   
			INNER JOIN	Products.ArtName an
				ON	an.art_name_id = s.art_name_id   
			INNER JOIN	Products.TechSize ts
				ON	ts.ts_id = spcvt.ts_id   
			INNER JOIN	Technology.TechAction ta
				ON	ta.ta_id = sts.ta_id   
			INNER JOIN	Technology.Element e
				ON	e.element_id = sts.element_id   
			INNER JOIN	Technology.Equipment eq
				ON	eq.equipment_id = sts.equipment_id   
			INNER JOIN	Settings.EmployeeSetting es   
			LEFT JOIN	Settings.DepartmentSetting ds
				ON	ds.department_id = es.department_id   
			INNER JOIN	Settings.OfficeSetting os
				ON	os.office_id = es.office_id
				ON	stsj.job_employee_id = es.employee_id   
			INNER JOIN	Manufactory.SPCV_TechnologicalSequenceJobCost stsjc
				ON	stsjc.discharge_id = sts.discharge_id
				AND	es.office_id = stsjc.office_id   
			LEFT JOIN  Manufactory.SketchSalaryExecution sse
				ON sse.sketch_id = s.sketch_id
			LEFT JOIN	(SELECT	c.spcvts_id,
			    	    	 		COUNT(1) cnt_ready
			    	    	 FROM	Manufactory.ProductUnicCode puc   
			    	    	 		INNER JOIN	Manufactory.Cutting c
			    	    	 			ON	c.cutting_id = puc.cutting_id
			    	    	 WHERE	puc.operation_id IN (8, 4, 3, 1, 6)
			    	    	 GROUP BY
			    	    	 	c.spcvts_id)ready
				ON	ready.spcvts_id = spcvt.spcvts_id
			OUTER APPLY (
			      	SELECT	SUM(csc.cnt) sew_count
			      	FROM	Manufactory.ContractorSewCount csc
			      	WHERE	csc.spcvts_id = spcvt.spcvts_id
			      ) ready_contr
			LEFT JOIN	(SELECT	stsjis.stsj_id,
			    	    	 		SUM(stsjis.cnt) cnt_salary
			    	    	 FROM	Manufactory.SPCV_TechnologicalSequenceJobInSalary stsjis
			    	    	 GROUP BY
			    	    	 	stsjis.stsj_id)salary
				ON	salary.stsj_id = stsj.stsj_id
			LEFT JOIN	(SELECT	stsj2.sts_id,
			         	 		stsj2.spcvts_id,
			         	 		SUM(stsjis2.cnt) cnt_salary
			         	 FROM	Manufactory.SPCV_TechnologicalSequenceJobInSalary stsjis2   
			         	 		INNER JOIN	Manufactory.SPCV_TechnologicalSequenceJob stsj2
			         	 			ON	stsj2.stsj_id = stsjis2.stsj_id
			         	 GROUP BY
			         	 	stsj2.sts_id,
			         	 	stsj2.spcvts_id)salary2
			         	 ON	salary2.sts_id = stsj.sts_id AND salary2.spcvts_id = stsj.spcvts_id
			LEFT JOIN	(SELECT	stsj3.sts_id,
			         	 		stsj3.spcvts_id,
			         	 		SUM(stsj3.close_cnt) sum_close_cnt
			         	 FROM	Manufactory.SPCV_TechnologicalSequenceJob stsj3
			         	 WHERE	stsj3.salary_close_dt IS NULL AND stsj3.close_cnt IS NOT NULL
			         	 GROUP BY
			         	 	stsj3.sts_id,
			         	 	stsj3.spcvts_id) job_close
			         	 ON	job_close.sts_id = stsj.sts_id AND job_close.spcvts_id = stsj.spcvts_id
	WHERE	stsj.close_dt IS NOT NULL
			AND stsj.close_cnt > 0
			AND	stsj.salary_close_dt IS NULL
			AND	(@office_id IS NULL OR es.office_id = @office_id)
	ORDER BY
		s.sketch_id,
		spcv.spcv_id,
		sts.operation_range,
		ts.ts_name
	