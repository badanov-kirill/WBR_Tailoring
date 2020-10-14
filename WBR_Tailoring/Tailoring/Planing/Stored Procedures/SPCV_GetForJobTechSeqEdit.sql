CREATE PROCEDURE [Planing].[SPCV_GetForJobTechSeqEdit]
	@art_name VARCHAR(100) = NULL,
	@spcv_id INT = NULL
AS
	SET NOCOUNT ON 
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED	
	
	SELECT	s.sketch_id,
			s.pic_count,
			s.tech_design,
			s.is_deleted,
			s.subject_id,
			s2.subject_name,
			an.art_name,
			s.brand_id,
			b.brand_name,
			pa.sa + pan.sa           sa,
			ct.ct_name,
			s.ct_id,
			oa.begin_employee_id     technolog_employee_id,
			spcv.spcv_id,
			spcv.cost_plan_year,
			spcv.cost_plan_month,
			spcv.comment,
			pan.nm_id
	FROM	Planing.SketchPlan sp   
			INNER JOIN	Planing.SketchPlanColorVariant spcv
				ON	spcv.sp_id = sp.sp_id   
			INNER JOIN	Products.ProdArticleNomenclature pan
				ON	pan.pan_id = spcv.pan_id   
			INNER JOIN	Products.ProdArticle pa
				ON	pa.pa_id = pan.pa_id   
			INNER JOIN	Products.Sketch s
				ON	s.sketch_id = sp.sketch_id   
			INNER JOIN	Products.[Subject] s2
				ON	s2.subject_id = s.subject_id   
			INNER JOIN	Products.ArtName an
				ON	an.art_name_id = s.art_name_id   
			INNER JOIN	Products.Brand b
				ON	b.brand_id = s.brand_id   
			INNER JOIN	Material.ClothType ct
				ON	ct.ct_id = s.ct_id   
			OUTER APPLY (
			      	SELECT	TOP(1) stj.begin_employee_id
			      	FROM	Products.SketchTechnologyJob stj
			      	WHERE	stj.sketch_id = s.sketch_id
			      			AND	stj.begin_employee_id IS NOT NULL
			      	ORDER BY
			      		stj.stj_id ASC
			      )                  oa
	WHERE	(@art_name IS NULL OR an.art_name LIKE @art_name + '%')
			AND	(@spcv_id IS NULL OR spcv.spcv_id = @spcv_id)
			AND EXISTS(
			          	SELECT	1
			          	FROM	Planing.SketchPlanColorVariantTS spcvt
			          	WHERE	spcvt.spcv_id = spcv.spcv_id
			          			AND	spcvt.cut_cnt_for_job > 0
			          )
	ORDER BY
		s.sketch_id DESC