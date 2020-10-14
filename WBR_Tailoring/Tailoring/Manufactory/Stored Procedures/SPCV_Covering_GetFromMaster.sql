CREATE PROCEDURE [Manufactory].[SPCV_Covering_GetFromMaster]
	@employee_id INT
AS
	SET NOCOUNT ON 
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	DECLARE @cv_status_placing TINYINT = 12 --Назначен в цех
	DECLARE @cv_status_rm_issue TINYINT = 14 --На выдаче материалов
	
	SELECT	cov.covering_id,
			CAST(cov.create_dt AS DATETIME) covering_create_dt,
			s.sketch_id,
			sp.sp_id,
			sp.ps_id,
			an.art_name,
			ISNULL(s.imt_name, sj.subject_name_sf) imt_name,
			s.sa,
			b.brand_name,
			spcv.spcv_name,
			spcv.spcv_id,
			sp.comment                    plan_comment,
			oa_c.x					      cv_comment,
			ISNULL(spcv.corrected_qty, spcv.qty) cv_qty,
			CAST(spcv.dt AS DATETIME)     spcv_dt,
			pa.sa + pan.sa                nm_sa,
			c.color_name                  main_color,
			s.pt_id,
			pt.pt_name,
			CAST(spcv.sew_deadline_dt AS DATETIME) sew_deadline_dt,
			spcv.sew_office_id,
			oa_ca.cutting_qty cutting_qty,
			CAST(sp.plan_sew_dt AS DATETIME) plan_sew_dt,
			CAST(spcv.deadline_package_dt AS DATETIME) deadline_package_dt
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
			INNER JOIN	Planing.CoveringDetail cd
			INNER JOIN	Planing.Covering cov
				ON	cov.covering_id = cd.covering_id
				ON	cd.spcv_id = spcv.spcv_id
				AND	cd.is_deleted = 0 			   
			INNER JOIN	Products.ProdArticleNomenclature pan   
			INNER JOIN	Products.ProdArticle pa
				ON	pa.pa_id = pan.pa_id   
			LEFT JOIN	Products.ProdArticleNomenclatureColor panc   
			INNER JOIN	Products.Color c
				ON	c.color_cod = panc.color_cod
				ON	panc.pan_id = pan.pan_id
				AND	panc.is_main = 1
				ON	pan.pan_id = spcv.pan_id			
			LEFT JOIN Planing.SketchPlanColorVariantCounter  oa_ca ON oa_ca.spcv_id = spcv.spcv_id
			OUTER APPLY (
					SELECT spcvc.comment + ' | '
					FROM Planing.SketchPlanColorVariantComment spcvc
					WHERE spcvc.spcv_id = spcv.spcv_id
					AND spcvc.ct_id = 2
					FOR XML PATH('')
			) oa_c(x)
	WHERE EXISTS (SELECT	1
	FROM	Planing.SketchPlanColorVariant spcv2  
			INNER JOIN	Planing.CoveringDetail cd2
				ON	cd2.spcv_id = spcv2.spcv_id   
			INNER JOIN	Planing.Covering c2
				ON	c2.covering_id = cd2.covering_id
	WHERE	spcv2.master_employee_id = @employee_id
			AND c2.covering_id = cov.covering_id
			AND	c2.close_dt IS NULL
			AND	spcv.cvs_id IN (@cv_status_placing, @cv_status_rm_issue)
			   )			
	ORDER BY
		cov.covering_id,
		an.art_name,
		sp.sketch_id,
		spcv.spcv_id