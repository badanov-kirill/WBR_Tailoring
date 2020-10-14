CREATE PROCEDURE [Manufactory].[CuttingInfo_FindBySA]
	@sa VARCHAR(36)
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED	
	
	SELECT	pan.nm_id,
			pa.sa + pan.sa              sa,
			ISNULL(s.imt_name, sj.subject_name_sf) imt_name,
			b.brand_name,
			ISNULL(pan.cutting_degree_difficulty, 1) cutting_degree_difficulty,
			pan.pan_id,
			an.art_name,
			s.pt_id,
			pt.pt_name,
			s.sa_local,
			ISNULL(oa_ts.cnt_ts, 0)     cnt_ts,
			ISNULL(oa_ts.cnt_not_perim, 0) cnt_not_perim,
			pa.sketch_id
	INTO	#t
	FROM	Products.ProdArticle pa   
			INNER JOIN	Products.ProdArticleNomenclature pan
				ON	pan.pa_id = pa.pa_id   
			INNER JOIN	Products.Sketch s
				ON	s.sketch_id = pa.sketch_id   
			INNER JOIN	Products.[Subject] sj
				ON	sj.subject_id = s.subject_id   
			INNER JOIN	Products.Brand b
				ON	b.brand_id = pa.brand_id   
			INNER JOIN	Products.ArtName an
				ON	an.art_name_id = s.art_name_id   
			LEFT JOIN	Products.ProductType pt
				ON	pt.pt_id = s.pt_id   
			OUTER APPLY (
			      	SELECT	SUM(CASE WHEN spp.ts_id IS NULL THEN 1 ELSE 0 END) cnt_not_perim,
			      			COUNT(1) cnt_ts
			      	FROM	Products.ProdArticleNomenclatureTechSize pants   
			      			LEFT JOIN	Products.SketchPatternPerimetr spp
			      				ON	spp.ts_id = pants.ts_id
			      				AND	spp.sketch_id = s.sketch_id
			      				AND	spp.perimetr > 0
			      	WHERE	pants.pan_id = pan.pan_id
			      	AND pants.is_deleted = 0
			      ) oa_ts
	WHERE	pa.sa LIKE @sa + '%'
			--AND	pan.nm_id IS NOT NULL
	
	SELECT	t.nm_id,
			t.sa,
			t.imt_name,
			t.brand_name,
			t.cutting_degree_difficulty,
			t.pan_id,
			t.art_name,
			t.pt_id,
			t.pt_name,
			t.sa_local,
			t.cnt_ts,
			t.cnt_not_perim,
			t.sketch_id
	FROM	#t t
	
	SELECT	pan.pan_id,
			ts.ts_name,
			ISNULL(spp.perimetr, 0) perimeter,
			pants.ts_id,
			pants.pants_id
	FROM	#t t   
			INNER JOIN	Products.ProdArticleNomenclature pan
				ON	pan.pan_id = t.pan_id   
			INNER JOIN	Products.ProdArticleNomenclatureTechSize pants
				ON	pants.pan_id = pan.pan_id   
			INNER JOIN	Products.TechSize ts
				ON	ts.ts_id = pants.ts_id   
			INNER JOIN	Products.ProdArticle pa
				ON	pa.pa_id = pan.pa_id   
			LEFT JOIN	Products.SketchPatternPerimetr spp
				ON	spp.sketch_id = pa.sketch_id
				AND	spp.ts_id = pants.ts_id
	WHERE pants.is_deleted = 0