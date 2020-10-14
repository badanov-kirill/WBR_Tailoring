CREATE PROCEDURE [Manufactory].[SPCV_TechnologicalSequenceJob_GetByMaster]
	@employee_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	spcv.spcv_id,
			s.sketch_id,
			b.brand_name,
			pa.sa + pan.sa                   sa,
			an.art_name,
			sj.subject_name,
			stsj.job_employee_id,
			ta.ta_name                       ta,
			e.element_name                   element,
			eq.equipment_name                equipment,
			sts.discharge_id,
			sts.operation_time,
			ts.ts_name,
			stsj.plan_cnt,
			stsj.employee_cnt,
			ts.ts_id,
			stsj.stsj_id,
			stsj.sts_id
	FROM	Manufactory.SPCV_TechnologicalSequenceJob stsj   
			INNER JOIN	Manufactory.SPCV_TechnologicalSequence sts
				ON	sts.sts_id = stsj.sts_id   
			INNER JOIN	Planing.SketchPlanColorVariantTS spcvt
				ON	spcvt.spcvts_id = stsj.spcvts_id   
			INNER JOIN	Planing.SketchPlanColorVariant spcv
				ON	spcv.spcv_id = sts.spcv_id   
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
			INNER JOIN	Settings.MasterEmployee me
				ON	me.employee_id = stsj.job_employee_id
	WHERE	me.master_employee_id = @employee_id
			AND	stsj.close_cnt IS NULL
			AND	stsj.employee_cnt IS NOT     NULL
	OPTION(RECOMPILE)