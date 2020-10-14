CREATE PROCEDURE [Manufactory].[SPCV_TechnologicalSequenceJob_GetByEmployee]
	@employee_id INT
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
			cd.comment,
			sts.discharge_id,
			sts.operation_time,
			stsj.plan_cnt,
			CAST(stsj.dt AS DATETIME)     dt,
			stsj.stsj_id,
			spcv.spcv_id,
			stsj.sts_id,
			stsjc.cost_per_hour * sts.operation_time / 3600 cost_operation
	FROM	Manufactory.SPCV_TechnologicalSequenceJob stsj   
			INNER JOIN	Manufactory.SPCV_TechnologicalSequence sts
				ON	sts.sts_id = stsj.sts_id   
			INNER JOIN Technology.CommentDict cd
				ON cd.comment_id = sts.comment_id
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
				ON	stsj.job_employee_id = es.employee_id   
			INNER JOIN	Manufactory.SPCV_TechnologicalSequenceJobCost stsjc
				ON	stsjc.discharge_id = sts.discharge_id
				AND	es.office_id = stsjc.office_id   
	WHERE	stsj.job_employee_id = @employee_id
			AND	stsj.close_cnt IS NULL
			AND	stsj.employee_cnt IS      NULL
	ORDER BY s.sketch_id, spcv.spcv_id, sts.operation_range, ts.ts_name
	