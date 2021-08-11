CREATE PROCEDURE [Products].[ProdArticleNomenclature_GetNoPhoto]
	@brand_id INT = NULL
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	b.brand_name,
			sj.subject_name,
			an.art_name,
			pa.sa + pan.sa sa,
			pan.nm_id,
			pan.pan_id
	FROM	Products.Sketch s   
			INNER JOIN	Products.ProdArticle pa
				ON	pa.sketch_id = s.sketch_id   
			INNER JOIN	Products.ProdArticleNomenclature pan
				ON	pan.pa_id = pa.pa_id   
			INNER JOIN	Products.ArtName an
				ON	an.art_name_id = s.art_name_id   
			INNER JOIN	products.Brand b
				ON	b.brand_id = s.brand_id   
			INNER JOIN	Products.[Subject] sj
				ON	sj.subject_id = s.subject_id
	WHERE	pan.pics_dt IS NULL
			AND	pan.nm_id IS NOT NULL
			AND	(@brand_id IS NULL OR s.brand_id = @brand_id)
