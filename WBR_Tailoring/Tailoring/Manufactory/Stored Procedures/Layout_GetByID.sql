CREATE PROCEDURE [Manufactory].[Layout_GetByID]
	@layout_id INT
AS
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON
	
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