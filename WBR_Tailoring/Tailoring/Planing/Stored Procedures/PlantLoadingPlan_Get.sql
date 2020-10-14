CREATE PROCEDURE [Planing].[PlantLoadingPlan_Get]
	@office_id INT = NULL,
	@start_dt DATE,
	@finish_dt DATE
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	sp.sp_id,
			sp.sketch_id,
			spcv.spcv_id,
			pa.sa + pan.sa     nm_sa,
			c.color_name       main_color,
			an.art_name,
			sj.subject_name,
			spcv.spcv_name,
			plp.qty,
			cast(plp.launch_dt AS DATETIME) launch_dt,
			cast(plp.finish_dt AS DATETIME) finish_dt,
			b.brand_name,
			ct.ct_name,
			os.office_name,
			sp.plan_year,
			sp.plan_month,
			CAST(spcv.deadline_package_dt AS DATETIME) deadline_package_dt,
			plp.office_id sew_office_id
	FROM	Planing.PlantLoadingPlan plp	  
			INNER JOIN	Planing.SketchPlanColorVariant spcv
				ON spcv.spcv_id = plp.spcv_id
			INNER JOIN Planing.SketchPlan sp 
				ON sp.sp_id = spcv.sp_id
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
				ON	os.office_id = plp.office_id   
			INNER JOIN	Products.ProdArticleNomenclature pan   
			INNER JOIN	Products.ProdArticle pa
				ON	pa.pa_id = pan.pa_id   
			LEFT JOIN	Products.ProdArticleNomenclatureColor panc   
			INNER JOIN	Products.Color c
				ON	c.color_cod = panc.color_cod
				ON	panc.pan_id = pan.pan_id
				AND	panc.is_main = 1
				ON	pan.pan_id = spcv.pan_id  

	WHERE	(@office_id IS NULL OR plp.office_id = @office_id)
			AND plp.launch_dt >= @start_dt
			AND plp.launch_dt <= @finish_dt
	ORDER BY
		plp.launch_dt,
		an.art_name,
		sp.sketch_id,
		spcv.spcv_id