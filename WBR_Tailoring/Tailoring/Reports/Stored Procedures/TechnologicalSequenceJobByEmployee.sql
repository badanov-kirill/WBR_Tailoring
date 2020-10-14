CREATE PROCEDURE [Reports].[TechnologicalSequenceJobByEmployee]
	@start_dt DATE,
	@finish_dt DATE,
	@employee_id INT = NULL
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	stsj.job_employee_id,
			stsj.plan_cnt,
			stsj.close_cnt,
			sts.operation_time,
			CAST(stsj.close_dt AS DATETIME) close_dt,
			pa.sa + pan.sa        sa,
			an.art_name,
			ts.ts_name,
			ta.ta_name            ta,
			e.element_name        element,
			eq.equipment_name     equipment,
			sts.discharge_id,
			stsjc.cost_per_hour,
			ISNULL(stsj.close_cnt, stsj.plan_cnt) * ROUND(stsjc.cost_per_hour * sts.operation_time / 3600, 2) cost_job,
			os.office_name
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
			LEFT JOIN	Manufactory.SPCV_TechnologicalSequenceJobCost stsjc
				ON	stsjc.discharge_id = sts.discharge_id
				AND	spcv.sew_office_id = stsjc.office_id   
			INNER JOIN	Settings.OfficeSetting os
				ON	os.office_id = spcv.sew_office_id
	WHERE	stsj.close_dt >= @start_dt
			AND	stsj.close_dt < @finish_dt
			AND	(@employee_id IS NULL OR stsj.job_employee_id = @employee_id)
			AND stsj.salary_close_dt IS NULL
			   	