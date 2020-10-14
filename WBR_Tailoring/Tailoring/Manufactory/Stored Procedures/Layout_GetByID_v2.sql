CREATE PROCEDURE [Manufactory].[Layout_GetByID_v2]
	@layout_id INT,
	@tl_id INT = NULL
AS
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON
	DECLARE @completing_up INT = 4
	
	SELECT	l.layout_id,
			l.frame_width,
			l.layout_length,
			l.effective_percent,
			l.base_sketch_id,
			an.art_name,
			sj.subject_name,
			l.base_completing_id,
			l.base_completing_number,
			l.base_consumption,
			l.is_deleted,
			l.comment
	FROM	Manufactory.Layout l   
			INNER JOIN	Products.Sketch s
				ON	s.sketch_id = l.base_sketch_id   
			INNER JOIN	Products.ArtName an
				ON	an.art_name_id = s.art_name_id   
			INNER JOIN	Products.[Subject] sj
				ON	sj.subject_id = s.subject_id
	WHERE	l.layout_id = @layout_id
	
	SELECT	lt.ts_id,
			lt.completing_qty
	FROM	Manufactory.LayoutTS lt
	WHERE	lt.layout_id = @layout_id
	
	SELECT	las.las_id,
			las.layout_id,
			las.sketch_id,
			st.st_name,
			s.pic_count,
			s.tech_design,
			an.art_name,
			sj.subject_name,
			s.sa,
			s.sa_local,
			c.completing_name,
			las.completing_id,
			las.completing_number,
			las.consumption,
			oa_ts.x ts
	FROM	Manufactory.LayoutAddedSketch las   
			INNER JOIN	Products.Sketch s
				ON	s.sketch_id = las.sketch_id   
			INNER JOIN	Products.SketchType st
				ON	st.st_id = s.st_id   
			INNER JOIN	Products.ArtName an
				ON	an.art_name_id = s.art_name_id   
			INNER JOIN	Products.Brand b
				ON	b.brand_id = s.brand_id   
			INNER JOIN	Products.[Subject] sj
				ON	sj.subject_id = s.subject_id   
			INNER JOIN	Material.Completing c
				ON	c.completing_id = las.completing_id   
			OUTER APPLY (
			      	SELECT	lasts.ts_id '@id',
			      			lasts.completing_qty '@qty'
			      	FROM	Manufactory.LayoutAddedSketchTS lasts
			      	WHERE	lasts.las_id = las.las_id
			      	FOR XML	PATH('ts'), ROOT('tss')
			      ) oa_ts(x)
			 
	WHERE	las.layout_id = @layout_id
			AND	las.is_deleted = 0
			
	SELECT	spcv.spcv_id,
			s.sketch_id,
			an.art_name,
			ISNULL(s.imt_name, sj.subject_name) imt_name,
			CASE 
			     WHEN spcv.pan_id IS NULL THEN s.sa
			     ELSE pa.sa + pan.sa
			END         sa,
			oa.color_name,
			oa.rmt_name,
			spcv.spcv_name
	FROM	Manufactory.LayoutAddedSketch las   
			INNER JOIN	Planing.SketchPlan sp
				ON	sp.sketch_id = las.sketch_id   
			INNER JOIN	Planing.SketchPlanColorVariant spcv
				ON	spcv.sp_id = sp.sp_id   
			INNER JOIN	Planing.AddedSketchPlanMapping aspm
				ON	aspm.linked_spcv_id = spcv.spcv_id   
			LEFT JOIN	Manufactory.TaskLayout tl
				ON	tl.spcv_id = aspm.base_spcv_id   
			INNER JOIN	Products.Sketch s
				ON	s.sketch_id = sp.sketch_id   
			INNER JOIN	Products.ArtName an
				ON	an.art_name_id = s.art_name_id   
			INNER JOIN	Products.[Subject] sj
				ON	sj.subject_id = s.subject_id   
			LEFT JOIN	Products.ProdArticleNomenclature pan
				ON	pan.pan_id = spcv.pan_id   
			LEFT JOIN	Products.ProdArticle pa
				ON	pa.pa_id = pan.pa_id   
			OUTER APPLY (
			      	SELECT	TOP(1) cc.color_name,
			      			rmt.rmt_name
			      	FROM	Planing.SketchPlanColorVariantCompleting spcvc   
			      			INNER JOIN	Material.RawMaterialType rmt
			      				ON	rmt.rmt_id = spcvc.rmt_id   
			      			INNER JOIN	Material.ClothColor cc
			      				ON	cc.color_id = spcvc.color_id
			      	WHERE	spcvc.spcv_id = spcv.spcv_id
			      	ORDER BY
			      		CASE 
			      		     WHEN spcvc.completing_id = @completing_up AND spcvc.completing_number = 1 THEN 0
			      		     ELSE 1
			      		END,
			      		CASE 
			      		     WHEN spcvc.comment IS NOT NULL THEN 0
			      		     ELSE 1
			      		END,
			      		spcvc.completing_number,
			      		spcvc.color_id     DESC,
			      		spcvc.spcvc_id     DESC
			      )     oa
	WHERE	las.layout_id = @layout_id
			AND	las.is_deleted = 0
			AND	spcv.is_deleted = 0
			AND	(@tl_id  IS NULL OR tl.tl_id = @tl_id)