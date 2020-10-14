CREATE PROCEDURE [Planing].[SketchPlanColorVariant_DataForMapping]
	@spcv_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	DECLARE @completing_up INT = 4
	
	SELECT	spcv2.spcv_id,
			spcv2.spcv_name,
			pa.sa + pan.sa     sa,
			pan.nm_id,
			oac.color_name     site_color_name,
			oa.color_name      cv_color_name
	FROM	Planing.SketchPlanColorVariant spcv   
			INNER JOIN	Planing.SketchPlanColorVariant spcv2
				ON	spcv2.sp_id = spcv.sp_id   
			LEFT JOIN	Products.ProdArticleNomenclature pan   
			INNER JOIN	Products.ProdArticle pa
				ON	pa.pa_id = pan.pa_id
				ON	pan.pan_id = spcv2.pan_id   
			OUTER APPLY (
			      	SELECT	TOP(1) c.color_name
			      	FROM	Products.ProdArticleNomenclatureColor panc   
			      			INNER JOIN	Products.Color c
			      				ON	c.color_cod = panc.color_cod
			      	WHERE	panc.pan_id = pan.pan_id
			      			AND	panc.is_main = 1
			      ) oac
			OUTER APPLY (
	      			SELECT	TOP(1) cc.color_name
	      			FROM	Planing.SketchPlanColorVariantCompleting spcvc    
	      					INNER JOIN	Material.ClothColor cc
	      						ON	cc.color_id = spcvc.color_id
	      			WHERE	spcvc.spcv_id = spcv2.spcv_id
	      			ORDER BY
	      				CASE 
	      					 WHEN spcvc.completing_id = @completing_up AND spcvc.completing_number = 1 THEN 0
	      					 ELSE 1
	      				END,
	      				spcvc.completing_number,
	      				spcvc.color_id     DESC,
	      				spcvc.spcvc_id     DESC
				  )                    oa
	WHERE	spcv.spcv_id = @spcv_id
			AND	spcv2.spcv_id != @spcv_id
			AND	spcv2.is_deleted = 0
	
	
	SELECT	pan.pan_id,
			pa.sa + pan.sa     sa,
			pan.nm_id,
			pa.pa_id,
			oac.color_name,
			pan.sa pan_sa
	FROM	Planing.SketchPlanColorVariant spcv   
			INNER JOIN	Planing.SketchPlan sp
				ON	sp.sp_id = spcv.sp_id   
			INNER JOIN	Products.Sketch s
				ON	s.sketch_id = sp.sketch_id   
			INNER JOIN	Products.ProdArticle pa
				ON	pa.sketch_id = s.sketch_id   
			INNER JOIN	Products.ProdArticleNomenclature pan
				ON	pan.pa_id = pa.pa_id   
			OUTER APPLY (
			      	SELECT	TOP(1) c.color_name
			      	FROM	Products.ProdArticleNomenclatureColor panc   
			      			INNER JOIN	Products.Color c
			      				ON	c.color_cod = panc.color_cod
			      	WHERE	panc.pan_id = pan.pan_id
			      			AND	panc.is_main = 1
			      )            oac
	WHERE	spcv.spcv_id = @spcv_id
			AND	pan.is_deleted = 0
			AND	pa.is_deleted = 0
			--AND	pan.nm_id IS NOT NULL
			AND	NOT EXISTS (
			   		SELECT	1
			   		FROM	Planing.SketchPlanColorVariant spcv2
			   		WHERE	spcv2.sp_id = sp.sp_id
			   				AND	spcv2.pan_id = pan.pan_id
			   	)
	ORDER BY
		pa.pa_id DESC,
		pan.pan_id DESC