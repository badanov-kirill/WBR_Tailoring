CREATE PROCEDURE [Planing].[SketchPlanColorVariant_GetForPlacing]
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	DECLARE @cv_status_confectione_end TINYINT = 10 --Конфекционная карта готова
	DECLARE @cv_status_pre_placing TINYINT = 17 --Подготовлен к запуску	
	
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
			sp.plan_year,
			sp.plan_month,
			oa_p.x                        pattern_office,
			pa.sa + pan.sa                nm_sa,
			c.color_name                  main_color,
			s.pt_id,
			pt.pt_name,
			spcv.sew_office_id,
			os.office_name sew_office_name,
			spcv.cvs_id,
			CAST(spcv.sew_deadline_dt AS DATETIME)     sew_deadline_dt,
			CAST(sp.plan_sew_dt AS DATETIME)     plan_sew_dt,
			pan.cutting_degree_difficulty,
			spcv.pan_id
	FROM	Planing.SketchPlan sp   
			INNER JOIN	Products.Sketch s
				ON	s.sketch_id = sp.sketch_id   
			LEFT JOIN Products.ProductType pt
				ON pt.pt_id = s.pt_id
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
			LEFT JOIN	Products.ProdArticleNomenclatureColor panc   
			INNER JOIN	Products.Color c
				ON	c.color_cod = panc.color_cod
				ON	panc.pan_id = pan.pan_id
				AND	panc.is_main = 1
				ON	pan.pan_id = spcv.pan_id   
			LEFT JOIN Settings.OfficeSetting os
				ON os.office_id = spcv.sew_office_id
			OUTER APPLY (
			      	SELECT	os.office_name + '; '
			      	FROM	Products.SketchBranchOfficePattern sbop   
			      			INNER JOIN	Settings.OfficeSetting os
			      				ON	os.office_id = sbop.office_id
			      	WHERE	sbop.sketch_id = s.sketch_id
			      	FOR XML	PATH('')
			      ) oa_p(x)
	WHERE	spcv.cvs_id IN (@cv_status_confectione_end, @cv_status_pre_placing)
			AND	spcv.is_deleted = 0
	ORDER BY
		sp.dt                             DESC,
		sp.sp_id,
		spcv.spcv_id
GO

