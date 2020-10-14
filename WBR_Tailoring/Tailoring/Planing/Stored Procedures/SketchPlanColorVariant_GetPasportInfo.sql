CREATE PROCEDURE [Planing].[SketchPlanColorVariant_GetPasportInfo]
	@employee_id INT = NULL
AS
	SET NOCOUNT ON 
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	DECLARE @cv_status_pasport_review TINYINT = 16 --Проверка паспортов ткани дизайнером
	DECLARE @completing_up INT = 4
	
	SELECT	s.sketch_id,
			sp.sp_id,
			sp.ps_id,
			an.art_name,
			ISNULL(s.imt_name, sj.subject_name_sf) imt_name,
			s.sa,
			b.brand_name,
			spcv.spcv_name,
			spcv.spcv_id,
			sp.comment                    plan_comment,
			spcv.comment                  cv_comment,
			ISNULL(spcv.corrected_qty, spcv.qty) cv_qty,
			CAST(spcv.dt AS DATETIME)     spcv_dt,
			s.pt_id,
			pt.pt_name,
			spcv.sew_office_id,
			oa.color_name,
			pa.sa + pan.sa     nm_sa,
			CAST(sp.to_purchase_dt AS DATETIME) to_purchase_dt,
			CASE 
			     WHEN sp.spp_id IS NULL THEN 0
			     ELSE 1
			END for_pre_plan
	FROM	Planing.SketchPlan sp   
			INNER JOIN	Products.Sketch s
				ON	s.sketch_id = sp.sketch_id   
			LEFT JOIN	Products.ProductType pt
				ON	pt.pt_id = s.pt_id   
			INNER JOIN	Products.ArtName an
				ON	an.art_name_id = s.art_name_id   
			INNER JOIN	Products.[Subject] sj
				ON	sj.subject_id = s.subject_id   
			INNER JOIN	Products.Brand b
				ON	b.brand_id = s.brand_id   
			INNER JOIN	Planing.SketchPlanColorVariant spcv
				ON	spcv.sp_id = sp.sp_id
			LEFT JOIN	Products.ProdArticleNomenclature pan   
			INNER JOIN	Products.ProdArticle pa
				ON	pa.pa_id = pan.pa_id
				ON	pan.pan_id = spcv.pan_id 
			OUTER APPLY (
	      			SELECT	TOP(1) cc.color_name
	      			FROM	Planing.SketchPlanColorVariantCompleting spcvc    
	      					INNER JOIN	Material.ClothColor cc
	      						ON	cc.color_id = spcvc.color_id
	      			WHERE	spcvc.spcv_id = spcv.spcv_id
	      			ORDER BY
	      				CASE 
	      					 WHEN spcvc.completing_id = @completing_up AND spcvc.completing_number = 1 THEN 0
	      					 ELSE 1
	      				END,
	      				spcvc.completing_number,
	      				spcvc.color_id     DESC,
	      				spcvc.spcvc_id     DESC
				  )                    oa
	WHERE	spcv.cvs_id IN (@cv_status_pasport_review)
			AND	(@employee_id IS NULL OR sp.create_employee_id = @employee_id)
			AND	spcv.is_deleted = 0
	ORDER BY
		an.art_name,
		sp.sketch_id,
		spcv.spcv_id