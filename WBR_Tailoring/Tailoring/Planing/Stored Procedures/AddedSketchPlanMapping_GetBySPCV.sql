CREATE PROCEDURE [Planing].[AddedSketchPlanMapping_GetBySPCV]
	@spcv_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	spcv.spcv_id,
			ISNULL(pa.sa + pan.sa, s2.sa) sa,
			pan.nm_id,
			ISNULL(an.art_name, an2.art_name) art_name,
			ISNULL(sj.subject_name, sj2.subject_name) subject_name,
			ISNULL(b.brand_name, b2.brand_name) brand_name,
			ISNULL(pa.sketch_id, s2.sketch_id) sketch_id,
			aspm.base_spcv_id
	FROM	Planing.AddedSketchPlanMapping aspm   
			INNER JOIN	Planing.SketchPlanColorVariant spcv
				ON	spcv.spcv_id = aspm.linked_spcv_id   
			LEFT JOIN	Products.ProdArticleNomenclature pan   
			INNER JOIN	Products.ProdArticle pa
				ON	pa.pa_id = pan.pa_id   
			INNER JOIN	Products.Sketch s
				ON	s.sketch_id = pa.sketch_id   
			INNER JOIN	Products.[Subject] sj
				ON	sj.subject_id = s.subject_id   
			INNER JOIN	Products.Brand b
				ON	b.brand_id = pa.brand_id   
			INNER JOIN	Products.ArtName an
				ON	an.art_name_id = s.art_name_id
				ON	pan.pan_id = spcv.pan_id   
			INNER JOIN	Planing.SketchPlan sp
				ON	sp.sp_id = spcv.sp_id   
			INNER JOIN	Products.Sketch s2
				ON	sp.sketch_id = s2.sketch_id   
			INNER JOIN	Products.[Subject] sj2
				ON	sj2.subject_id = s2.subject_id   
			INNER JOIN	Products.Brand b2
				ON	b2.brand_id = s2.brand_id   
			INNER JOIN	Products.ArtName an2
				ON	an2.art_name_id = s2.art_name_id
	WHERE	aspm.base_spcv_id = @spcv_id