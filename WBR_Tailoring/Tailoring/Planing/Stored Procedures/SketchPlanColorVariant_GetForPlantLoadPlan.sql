CREATE PROCEDURE [Planing].[SketchPlanColorVariant_GetForPlantLoadPlan]
	@office_id INT = NULL
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	DECLARE @cv_status_placing TINYINT = 12 --Назначен в цех
	DECLARE @cv_status_rm_issue TINYINT = 14 --На выдаче материалов
	
	SELECT	sp.sp_id,
			sp.sketch_id,
			spcv.spcv_id,
			pa.sa + pan.sa     nm_sa,
			c.color_name       main_color,
			an.art_name,
			sj.subject_name,
			spcv.spcv_name,
			ISNULL(spcv.corrected_qty, spcv.qty) qty,
			b.brand_name,
			ct.ct_name,
			os.office_name,
			sp.plan_year,
			sp.plan_month,
			CAST(spcv.deadline_package_dt AS DATETIME) deadline_package_dt,
			CAST(spcv.sew_deadline_dt  AS DATETIME) sew_deadline_dt,
			oa_c.x             comment,
			spcv.sew_office_id
	FROM	Planing.SketchPlan sp   
			INNER JOIN	Planing.SketchPlanColorVariant spcv
				ON	spcv.sp_id = sp.sp_id   
			INNER JOIN	Products.Sketch s
				ON	s.sketch_id = sp.sketch_id   
			INNER JOIN	Products.Brand b
				ON	b.brand_id = s.brand_id   
			INNER JOIN	Material.ClothType ct
				ON	ct.ct_id = s.ct_id   
			INNER JOIN	Products.[Subject] sj
				ON	sj.subject_id = s.subject_id   
			INNER JOIN	Products.ArtName an
				ON	an.art_name_id = s.art_name_id   
			LEFT JOIN	Settings.OfficeSetting os
				ON	os.office_id = spcv.sew_office_id   
			INNER JOIN	Products.ProdArticleNomenclature pan   
			INNER JOIN	Products.ProdArticle pa
				ON	pa.pa_id = pan.pa_id   
			LEFT JOIN	Products.ProdArticleNomenclatureColor panc   
			INNER JOIN	Products.Color c
				ON	c.color_cod = panc.color_cod
				ON	panc.pan_id = pan.pan_id
				AND	panc.is_main = 1
				ON	pan.pan_id = spcv.pan_id   
			OUTER APPLY (
	      			SELECT	spcvc.comment + ' | '
	      			FROM	Planing.SketchPlanColorVariantComment spcvc
	      			WHERE	spcvc.spcv_id = spcv.spcv_id
	      			FOR XML	PATH('')
				  ) oa_c(x)
	WHERE	(
	     		spcv.cvs_id 
	     		IN (@cv_status_placing, @cv_status_rm_issue)
	     		
	     	)
			AND	(@office_id IS NULL OR spcv.sew_office_id = @office_id)
			AND	spcv.is_deleted = 0
			AND	NOT EXISTS (
			   		SELECT	1
			   		FROM	Planing.PlantLoadingPlan plp
			   		WHERE	plp.spcv_id = spcv.spcv_id
			   	)
	ORDER BY
		an.art_name,
		sp.sketch_id,
		spcv.spcv_id