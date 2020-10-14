CREATE PROCEDURE [Manufactory].[SPCV_GetForCheckTechSeq]
AS
	SET NOCOUNT ON 
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED	
	
	SELECT	qp.qp_name,
			CAST(sfts.plan_dt AS DATETIME) plan_dt,
			s.sketch_id,
			s.pic_count,
			s.tech_design,
			s2.subject_name,
			an.art_name,
			b.brand_name,
			pa.sa + pan.sa       sa,
			ct.ct_name,
			spcv.spcv_id,
			es.employee_name     technology_employee_name,
			sfts.spcvfts_id,
			sfts.proirity_level
	FROM	Manufactory.SPCV_ForTechSeq sfts   
			INNER JOIN	Planing.SketchPlanColorVariant spcv
				ON	spcv.spcv_id = sfts.spcv_id   
			INNER JOIN	Planing.SketchPlan sp
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
			LEFT JOIN	Settings.EmployeeSetting es
				ON	sfts.base_technolog_employee_id = es.employee_id   
			INNER JOIN	Products.QueuePriority qp
				ON	qp.qp_id = sfts.qp_id
	WHERE	sfts.start_dt IS     NULL
	ORDER BY
		sfts.qp_id ASC,
		sfts.proirity_level DESC,
		sfts.plan_dt ASC
